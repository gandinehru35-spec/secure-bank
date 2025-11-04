# 1. Create the custom VPC
resource "google_compute_network" "vpc_securebank" {
  name                    = "vpc-securebank"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# 2. Create the GKE Subnet
# This subnet has three IP ranges, which is the core of VPC-Native networking.
resource "google_compute_subnetwork" "subnet_gke" {
  name                     = "subnet-gke"
  ip_cidr_range            = "10.10.1.0/24" # <-- Primary range for Nodes
  network                  = google_compute_network.vpc_securebank.id
  region                   = var.gcp_region
  private_ip_google_access = true # Allows nodes to reach Google APIs (e.g., GCR, SM)

  # Secondary range for Pods
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  # Secondary range for Services
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

# 3. Create the separate subnet for Data Services (Cloud SQL, Memorystore)
resource "google_compute_subnetwork" "subnet_data_services" {
  name                     = "subnet-data-services"
  ip_cidr_range            = "10.10.2.0/24"
  network                  = google_compute_network.vpc_securebank.id
  region                   = var.gcp_region
  private_ip_google_access = true
}

# 4. Reserve a private IP for the Cloud SQL instance
resource "google_compute_global_address" "sql_private_ip" {
  name          = "sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_securebank.id
}

# 5. Create the VPC Peering for Cloud SQL
# This is the single, correct block.
resource "google_service_networking_connection" "sql_peering" {
  network                 = google_compute_network.vpc_securebank.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_private_ip.name]

  # This dependency fixes the API error
  depends_on = [
    google_project_service.servicenetworking_api
  ]
}

