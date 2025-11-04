# This file enables Policy Controller by registering the cluster to a GKE Hub (Fleet)

# 1. Register our cluster as a "membership" in the fleet
# (This resource was correct)
resource "google_gke_hub_membership" "membership" {
  provider = google-beta

  project       = var.project_id
  membership_id = "${var.cluster_name}-membership"
  location      = "global" # GKE Hub memberships are global

  endpoint {
    gke_cluster {
      # This links to the cluster created in gke.tf
      resource_link = "//container.googleapis.com/${google_container_cluster.securebank_cluster.id}"
    }
  }

  # --- THIS IS THE FIX ---
  # Wait for the cluster AND all nodepools to be 100% ready
  # before attempting to register the cluster. This fixes the
  # "cluster is currently running another operation" race condition.
  depends_on = [
    google_container_node_pool.np_general_services,
    google_container_node_pool.np_data_processing,
    google_container_node_pool.np_ingress
  ]
}

# 2. Enable the "policycontroller" feature for the ENTIRE FLEET
# (This resource was correct)
resource "google_gke_hub_feature" "policy_controller_feature" {
  provider = google-beta

  name     = "policycontroller"
  project  = var.project_id
  location = "global" # Features are global

  # We must wait for the GKE Hub API to be enabled
  depends_on = [
    google_project_service.gkehub_api,
    google_project_service.policycontroller_api
  ]
}

# 3. Link the Fleet Feature (Step 2) to the Cluster Membership (Step 1)
# (This resource was correct)
resource "google_gke_hub_feature_membership" "policy_controller_membership" {
  provider = google-beta

  project  = var.project_id
  location = "global" # Must match feature location

  # The feature we are linking
  feature = google_gke_hub_feature.policy_controller_feature.name
  # The cluster we are linking it to
  membership = google_gke_hub_membership.membership.id

  # This is the configuration for Policy Controller
  # This block is what actually installs and enables it on your cluster.
  policycontroller {
    policy_controller_hub_config {
      install_spec = "INSTALL_SPEC_ENABLED"
      # --- THIS IS THE FIX ---
      # The policy_content block was optional and causing the API error.
      # We have removed it to simplify the request.
    }
  }

  # Wait for both the feature and the membership to exist
  depends_on = [
    google_gke_hub_feature.policy_controller_feature,
    google_gke_hub_membership.membership
  ]
}

