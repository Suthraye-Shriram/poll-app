# VPC Network
resource "google_compute_network" "vpc" {
  name                    = local.vpc_name
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = local.subnet_name
  region        = local.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.0.0/24"  # Small CIDR for a small cluster

  # Enable private Google access for services like Cloud SQL
  private_ip_google_access = true

  # Secondary IP ranges for pods and services
  secondary_ip_range {
    range_name    = "${local.subnet_name}-pods"
    ip_cidr_range = "10.1.0.0/16"  # Range for pods
  }

  secondary_ip_range {
    range_name    = "${local.subnet_name}-services"
    ip_cidr_range = "10.2.0.0/20"  # Range for services
  }
}

# Firewall rule to allow internal communication with more specific rules
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name

  # Allow ICMP for ping/traceroute
  allow {
    protocol = "icmp"
  }

  # Allow specific TCP ports necessary for Kubernetes and app services
  allow {
    protocol = "tcp"
    ports    = ["443", "8080", "8443", "10250", "6443", "5432"]  # Common ports for K8s, web, and DB
  }

  # Allow UDP for DNS and other essential services
  allow {
    protocol = "udp"
    ports    = ["53", "8472"]  # DNS and VXLAN (Flannel)
  }

  source_ranges = ["10.0.0.0/24", "10.1.0.0/16", "10.2.0.0/20"]
}

# NAT Gateway and Router for outbound internet access from private instances
resource "google_compute_router" "router" {
  name    = "poll-app-router"
  region  = local.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "poll-app-nat"
  router                             = google_compute_router.router.name
  region                             = local.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
} 