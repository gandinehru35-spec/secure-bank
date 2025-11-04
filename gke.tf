# GKE Cluster Resource
resource "google_container_cluster" "securebank_cluster" {
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

  # --- Security: Private Nodes ---
  # We are REMOVING 'enable_private_endpoint = true'.
  # This makes the control plane public, so 'master_authorized_networks_config'
  # can work with your public bastion_ip.
  # We are KEEPING 'enable_private_nodes = true', which is key to our design.
  private_cluster_config {
    enable_private_nodes = true

    # This is the internal range for the master to talk to private nodes
    master_ipv4_cidr_block = "172.20.0.0/28"

    # We REMOVE the 'master_global_access_config' block, as it's not needed.
  }

  # This block will now work, as it's fire-walling a public endpoint.
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
  }

  # --- Security: Workload Identity ---
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  # We must depend on the APIs being enabled
  depends_on = [
    google_service_networking_connection.sql_peering,
    google_project_service.gkehub_api,
    google_project_service.policycontroller_api
  ]
}

