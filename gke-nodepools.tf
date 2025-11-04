# This file defines the specialized node pools for the SecureBank cluster

# 1. Node Pool: np-general-services
resource "google_container_node_pool" "np_general_services" {
  name       = "np-general-services"
  cluster    = google_container_cluster.securebank_cluster.name
  location   = var.gke_region # This creates 1 node per zone in the region (3 total)
  node_count = 1

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 20 # <-- QUOTA FIX: 100GB is default, 20GB fits quota

    # Enable Shielded GKE Nodes for security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Use Workload Identity
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# 2. Node Pool: np-data-processing
resource "google_container_node_pool" "np_data_processing" {
  name       = "np-data-processing"
  cluster    = google_container_cluster.securebank_cluster.name
  node_count = 1

  # --- THIS IS THE FIX ---
  # The nodepool's location MUST match the cluster's location (regional)
  location = var.gke_region

  # To fix the CPU quota, we specify ONLY ONE ZONE for this nodepool
  node_locations = [var.gcp_zone] # e.g., ["us-central1-a"]
  # -----------------------

  node_config {
    machine_type = "c2-standard-8" # Compute-optimized
    disk_size_gb = 20 # <-- QUOTA FIX: 100GB is default, 20GB fits quota

    # Enable Shielded GKE Nodes for security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # --- Taint ---
    taint {
      key    = "workload-type"
      value  = "data-processing"
      effect = "NO_SCHEDULE"
    }

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# 3. Node Pool: np-ingress
resource "google_container_node_pool" "np_ingress" {
  name       = "np-ingress"
  cluster    = google_container_cluster.securebank_cluster.name
  location   = var.gke_region # This creates 1 node per zone in the region (3 total)
  node_count = 1

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 20 # <-- QUOTA FIX: 100GB is default, 20GB fits quota

    # Enable Shielded GKE Nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # --- Taint ---
    taint {
      key    = "workload-type"
      value  = "ingress"
      effect = "NO_SCHEDULE"
    }

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

