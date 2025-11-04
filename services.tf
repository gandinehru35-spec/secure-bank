# This file provisions all external managed services for SecureBank

# --- 1. Cloud SQL for 'accounts-service' ---

# Create a random password for the database
resource "random_password" "sql_password" {
  length  = 20
  special = false # Avoid special characters for simplicity
}

# Provision the PostgreSQL instance
resource "google_sql_database_instance" "sql_accounts" {
  project          = var.project_id
  name             = "sql-accounts-prod"
  database_version = "POSTGRES_14"
  region           = var.gcp_region

  settings {
    tier = "db-g1-small" # Good for examples. Use a larger 'db-custom' for prod.
    availability_type = "ZONAL" # Use 'REGIONAL' for high availability in prod.

    # This is the critical security setting
    ip_configuration {
      ipv4_enabled    = false # No public IP
      private_network = google_compute_network.vpc_securebank.id
      # The 'allocated_peering_range_name' argument has been removed as it's no longer supported.
    }
  }

  # Set deletion_protection to true in a real production environment
  deletion_protection = false

  # This is crucial. It waits for the VPC peering to be active
  # before trying to create the instance in that network.
  depends_on = [
    google_service_networking_connection.sql_peering
  ]
}

# Create the specific database within the instance
resource "google_sql_database" "accounts_db" {
  project  = var.project_id
  instance = google_sql_database_instance.sql_accounts.name
  name     = "accounts_db"
}

# Create the application user for the database
resource "google_sql_user" "accounts_user" {
  project  = var.project_id
  instance = google_sql_database_instance.sql_accounts.name
  name     = "accounts_user"
  password = random_password.sql_password.result
}

# --- 2. Memorystore (Redis) for 'auth-service' ---

resource "google_redis_instance" "redis_auth" {
  project = var.project_id
  name    = "redis-auth-session"
  tier    = "BASIC" # Use 'STANDARD_HA' for high availability in prod.
  
  # Redis is zonal, so we provide both region and zone
  region      = var.gcp_region
  location_id = var.gcp_zone

  memory_size_gb = 1
  
  # Connects to our VPC using the same private service access
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  authorized_network = google_compute_network.vpc_securebank.id

  # Enable in-transit encryption
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  depends_on = [
    google_service_networking_connection.sql_peering
  ]
}

# --- 3. Google Service Accounts (GSAs) ---
# Create the dedicated identities for our microservices

resource "google_service_account" "gsa_accounts" {
  project      = var.project_id
  account_id   = "gsa-accounts-service"
  display_name = "Accounts Service GSA"
}

resource "google_service_account" "gsa_auth" {
  project      = var.project_id
  account_id   = "gsa-auth-service"
  display_name = "Auth Service GSA"
}

# --- 4. GSA IAM Permissions ---
# Grant 'accounts-service' GSA permission to connect to Cloud SQL

resource "google_project_iam_member" "accounts_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = google_service_account.gsa_accounts.member
}

# --- 5. Secret Manager & Secret IAM ---
# Store credentials in Secret Manager and grant GSAs access

# DB Password Secret
resource "google_secret_manager_secret" "sql_pass" {
  project   = var.project_id
  secret_id = "db-password"
  
  # --- THIS IS THE FIX ---
  # Using an explicit user_managed replication policy
  replication {
    user_managed {
      replicas {
        location = var.gcp_region # Replicate in our primary region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "sql_pass_v1" {
  secret      = google_secret_manager_secret.sql_pass.id
  secret_data = random_password.sql_password.result
}

# Grant 'accounts-service' GSA access to the DB password
resource "google_secret_manager_secret_iam_member" "accounts_read_db_pass" {
  project   = google_secret_manager_secret.sql_pass.project
  secret_id = google_secret_manager_secret.sql_pass.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.gsa_accounts.member
}

# --- Redis Host Secret ---
resource "google_secret_manager_secret" "redis_host" {
  project   = var.project_id
  secret_id = "redis-host"

  # --- THIS IS THE FIX ---
  replication {
    user_managed {
      replicas {
        location = var.gcp_region # Replicate in our primary region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "redis_host_v1" {
  secret      = google_secret_manager_secret.redis_host.id
  # Store the private IP address of the Redis instance
  secret_data = google_redis_instance.redis_auth.host
}

# Grant 'auth-service' GSA access to the Redis host
resource "google_secret_manager_secret_iam_member" "auth_read_redis_host" {
  project   = google_secret_manager_secret.redis_host.project
  secret_id = google_secret_manager_secret.redis_host.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.gsa_auth.member
}

# --- Redis Port Secret ---
resource "google_secret_manager_secret" "redis_port" {
  project   = var.project_id
  secret_id = "redis-port"

  # --- THIS IS THE FIX ---
  replication {
    user_managed {
      replicas {
        location = var.gcp_region # Replicate in our primary region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "redis_port_v1" {
  secret      = google_secret_manager_secret.redis_port.id
  # Store the port of the Redis instance
  secret_data = google_redis_instance.redis_auth.port
}

# Grant 'auth-service' GSA access to the Redis port
resource "google_secret_manager_secret_iam_member" "auth_read_redis_port" {
  project   = google_secret_manager_secret.redis_port.project
  secret_id = google_secret_manager_secret.redis_port.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.gsa_auth.member
}

