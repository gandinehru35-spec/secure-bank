# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.50.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.project_id
  region  = var.gcp_region
}

# --- CORE APIs FOR TERRAFORM ---
resource "google_project_service" "serviceusage_api" {
  project            = var.project_id
  service            = "serviceusage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager_api" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.serviceusage_api]
}

resource "google_project_service" "servicenetworking_api" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.serviceusage_api]
}

# --- APPLICATION APIs ---
resource "google_project_service" "gkehub_api" {
  project            = var.project_id
  service            = "gkehub.googleapis.com"
  disable_on_destroy = false
  depends_on = [
    google_project_service.serviceusage_api,
    google_project_service.cloudresourcemanager_api
  ]
}

resource "google_project_service" "policycontroller_api" {
  project            = var.project_id
  service            = "anthospolicycontroller.googleapis.com"
  disable_on_destroy = false
  depends_on = [
    google_project_service.serviceusage_api,
    google_project_service.cloudresourcemanager_api
  ]
}

# --- CI/CD APIs (NEW) ---
resource "google_project_service" "artifactregistry_api" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.serviceusage_api]
}

resource "google_project_service" "iamcredentials_api" {
  project            = var.project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.serviceusage_api]
}

