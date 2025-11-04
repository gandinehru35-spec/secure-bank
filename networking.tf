# 1. Create a Cloud Router
# Cloud NAT requires a Cloud Router to function.
resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = var.gcp_region
  network = google_compute_network.vpc_securebank.id
}

# 2. Create the Cloud NAT Gateway
# This gives our private nodes and pods a path to the internet for egress.
resource "google_compute_router_nat" "nat_gateway" {
  name   = "nat-gateway"
  router = google_compute_router.router.name
  region = var.gcp_region

  # This is the key setting from our design:
  # Provide NAT for all subnets, including primary (nodes) and secondary (pods).
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Automatically allocate public IPs for egress
  nat_ip_allocate_option = "AUTO_ONLY"
}

# 3. Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "fw-allow-internal"
  network = google_compute_network.vpc_securebank.name
  
  # Allow all traffic between any resources inside our VPC
  allow {
    protocol = "all"
  }
  source_ranges = ["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/20"]
}

resource "google_compute_firewall" "allow_gke_health_checks" {
  name    = "fw-allow-gke-health-checks"
  network = google_compute_network.vpc_securebank.name
  
  # GKE Control Plane needs to health check nodes and services
  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }
  source_ranges = ["172.16.0.32/28"] # <-- GKE Control Plane range (example)
                                     # This will be populated by the cluster resource
}
