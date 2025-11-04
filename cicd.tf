# --- 1. ARTIFACT REGISTRY & IDENTITY ---

# Resource to store our Docker images
resource "google_artifact_registry_repository" "docker_repo" {
  project      = var.project_id
  location     = var.gcp_region
  repository_id = "securebank-docker-repo"
  description  = "Docker images for Project SecureBank microservices."
  format       = "DOCKER"
}

# GSA that GitHub Actions will impersonate
resource "google_service_account" "gsa_github_actions" {
  project      = var.project_id
  account_id   = "gsa-github-actions"
  display_name = "GitHub Actions CI/CD Deployer"
}

# Workload Identity Pool to trust GitHub's OIDC tokens
resource "google_iam_workload_identity_pool" "github_pool" {
  project                  = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name             = "GitHub OIDC Pool"
  disabled                 = false
}

# Provider that connects the GitHub OIDC provider to the pool
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                              = var.project_id
  workload_identity_pool_id            = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id   = "github-provider"
  display_name                         = "GitHub OIDC Provider"
  disabled                             = false

  # This is the standard GitHub OIDC endpoint
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  
  # CRITICAL FIX: The attribute condition is mandatory and references the token claim
  # We are filtering on the raw 'repository' claim which is 'gandinehru35-spec/secure-bank'
  attribute_condition = "assertion.repository == '${var.github_repo}'"

  # Map the GitHub claims to Google Cloud attributes
  attribute_mapping = {
    "google.subject" = "assertion.sub"
    "attribute.actor" = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
}

# --- 2. IAM BINDINGS (PERMISSIONS) ---

# 1. Grant GSA Workload Identity User Role (THE FIX IS HERE)
# This allows the pool to grant temporary credentials to the GSA
resource "google_service_account_iam_member" "github_impersonate" {
  service_account_id = google_service_account.gsa_github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  
  # FIX: We use 'attribute.repository' directly, which aligns with the WIF best practice
  # The WIF system handles the subject prefix internally.
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# 2. Grant GSA Artifact Registry Writer
# This allows the CI/CD pipeline to push Docker images
resource "google_artifact_registry_repository_iam_member" "github_ar_writer" {
  project    = var.project_id
  location   = var.gcp_region
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.gsa_github_actions.member
}

# 3. Grant GSA Project Owner Role
# This grants the necessary cluster-level permissions (like container.clusterRoles.delete) 
# needed by Helm when deploying CSI drivers and other cluster-scoped resources.
resource "google_project_iam_member" "github_project_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = google_service_account.gsa_github_actions.member
}