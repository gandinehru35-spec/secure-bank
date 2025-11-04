# GKE Cluster Resource
resource "google_container_cluster" "securebank_cluster" {
  # We use the 'google-beta' provider for the policy_controller feature
  provider = google-beta

  name     = var.cluster_name
  location = var.gke_region

  # --- Networking ---
  network    = google_compute_network.vpc_securebank.id
  subnetwork = google_compute_subnetwork.subnet_gke.id

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnet_gke.secondary_ip_range[1].range_name
    services_secondary_range_name = google_compute_subnetwork.subnet_gke.secondary_ip_range[0].range_name
  }

  # --- Security: Public Control Plane, Private Nodes ---
  # We have private nodes
  private_cluster_config {
    enable_private_nodes = true
  }

  # But we have a firewalled public endpoint for kubectl/CI-CD
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.bastion_ip
      display_name = "Bastion/Office Access"
    }
  }

  # --- Calico Configuration ---
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # --- Addons Configuration ---
  addons_config {
    # This just enables the K8s NetworkPolicy API
    network_policy_config {
      disabled = false
    }

    # 'secret_manager_config' was incorrectly placed here
  }

  # --- THIS IS THE FIX ---
  # secret_manager_config is a top-level argument
  secret_manager_config {
    enabled = true
  }

  # --- Security: Workload Identity ---
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # We create our own node pools
  remove_default_node_pool = true
  initial_node_count       = 1

  # We must depend on the APIs being enabled
  depends_on = [
    google_service_networking_connection.sql_peering,
    google_project_service.gkehub_api,
    google_project_service.policycontroller_api
  ]
}

