# This file provisions the CI/CD resources:
# 1. Artifact Registry to store Docker images
# 2. GSA for GitHub Actions
# 3. OIDC (Workload Identity Federation) to connect GitHub to GCP
# 4. IAM permissions for the CI/CD pipeline

# --- 1. Artifact Registry ---

# API is enabled in provider.tf

# Create the Docker repository
resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  repository_id = "securebank-docker-repo"
  location      = var.gcp_region
  format        = "DOCKER"

  depends_on = [
    # Depend on the API being enabled in provider.tf
    google_project_service.artifactregistry_api
  ]
}

# --- 2. GSA (Google Service Account) for GitHub Actions ---

resource "google_service_account" "gsa_github_actions" {
  project      = var.project_id
  account_id   = "gsa-github-actions"
  display_name = "GitHub Actions CI/CD GSA"
}

# --- 3. OIDC (Workload Identity Federation) ---

# API is enabled in provider.tf

# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub OIDC Pool"
}

# Create the OIDC Provider for the pool
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project = var.project_id

  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  # Map attributes from the GitHub OIDC token
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Tell Google to trust GitHub's token issuer
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # The condition must be present and must match the token's claim exactly.
  attribute_condition = "assertion.repository == '${var.github_repo}'"

  depends_on = [
    # Depend on the API being enabled in provider.tf
    google_project_service.iamcredentials_api
  ]
}

# --- 4. IAM Permissions for the CI/CD Pipeline ---

# Grant the GSA permission to push to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "github_ar_writer" {
  project    = google_artifact_registry_repository.docker_repo.project
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.gsa_github_actions.member
}

# Grant the GSA permission to deploy to GKE
resource "google_project_iam_member" "github_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer" # Basic role to list clusters, etc.
  member  = google_service_account.gsa_github_actions.member
}

# Grant the GSA permission to update the cluster's firewall
resource "google_project_iam_member" "github_gke_admin" {
  project = var.project_id
  role    = "roles/container.clusterAdmin"
  member  = google_service_account.gsa_github_actions.member
}

# Allow GitHub to impersonate the GSA
resource "google_service_account_iam_member" "github_impersonate" {
  service_account_id = google_service_account.gsa_github_actions.name
  role               = "roles/iam.workloadIdentityUser"

  # --- THIS IS THE FIX ---
  # The "repo:" prefix was incorrect and caused the PERMISSION_DENIED error.
  # This syntax correctly references the mapped attribute.
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

