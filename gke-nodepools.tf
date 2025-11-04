# This file defines the specialized node pools for the cluster.
# We are using Workload Identity (workload_metadata_config) on all pools,
# which is required for the Secret Manager CSI driver to function.

# 1. Node Pool: np-general-services
resource "google_container_node_pool" "np_general_services" {
  name     = "np-general-services"
  cluster  = google_container_cluster.securebank_cluster.name
  location = var.gke_region # Location must be the cluster's region

  # --- THIS IS THE FIX ---
  # We limit this to a single zone to reduce CPU quota usage
  node_locations = [var.gcp_zone] # e.g., ["us-central1-a"]
  node_count     = 1
  # -----------------------

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 20 # Use 20GB to stay within quota

    # Use Workload Identity instead of oauth_scopes
    # This is required for the Secret Manager CSI driver
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

# 2. Node Pool: np-data-processing
resource "google_container_node_pool" "np_data_processing" {
  name     = "np-data-processing"
  cluster  = google_container_cluster.securebank_cluster.name
  location = var.gke_region # Location must be the cluster's region

  # We limit this to a single zone to fit our 8-CPU quota
  node_locations = [var.gcp_zone] # e.g., ["us-central1-a"]
  node_count     = 1

  node_config {
    machine_type = "e2-standard-8" # 8 CPUs
    disk_size_gb = 20              # Use 20GB to stay within quota

    # Use Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Taint to only allow data-processing pods
    taint {
      key    = "workload-type"
      value  = "data-processing"
      effect = "NO_SCHEDULE"
    }
  }
}

# 3. Node Pool: np-ingress
resource "google_container_node_pool" "np_ingress" {
  name     = "np-ingress"
  cluster  = google_container_cluster.securebank_cluster.name
  location = var.gke_region # Location must be the cluster's region

  # --- THIS IS THE FIX ---
  # We limit this to a single zone to reduce CPU quota usage
  node_locations = [var.gcp_zone] # e.g., ["us-central1-a"]
  node_count     = 1
  # -----------------------

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 20 # Use 20GB to stay within quota

    # Use Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Taint to only allow ingress pods
    taint {
      key    = "workload-type"
      value  = "ingress"
      effect = "NO_SCHEDULE"
    }
  }
}

