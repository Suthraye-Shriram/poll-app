# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = local.gke_cluster_name
  location = local.location
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "${local.subnet_name}-pods"
    services_secondary_range_name = "${local.subnet_name}-services"
  }

  # Use private cluster for better security
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # Allow access from the public internet to the control plane
    master_ipv4_cidr_block  = "172.16.0.0/28"  # Control plane IP range
  }

  # Define a release channel for automatic upgrades
  release_channel {
    channel = "REGULAR"  # Options: UNSPECIFIED, RAPID, REGULAR, STABLE
  }

  depends_on = [
    google_project_service.container,
    google_compute_subnetwork.subnet
  ]

  # Disable basic auth and client certificate
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = local.location
  cluster    = google_container_cluster.primary.name
  node_count = 1

  # Use e2-small instead of e2-micro for better performance
  node_config {
    machine_type = "e2-small"  # Better performance for production workloads
    disk_size_gb = 10  # Minimum allowed
    disk_type    = "pd-standard"

    # Google recommends custom service accounts with minimum permissions
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Add labels and tags as needed
    tags = ["poll-app-node"]
    # Keep the resource labels to avoid modification issues
    resource_labels = {
      "goog-gke-node-pool-provisioning-model" = "on-demand"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Add kubelet config to avoid modification errors
    kubelet_config {
      cpu_manager_policy = "none"
      cpu_cfs_quota      = false
      pod_pids_limit     = 0
    }
  }

  # Use latest GKE release channel for auto-upgrades
  management {
    auto_repair  = true
    auto_upgrade = true
  }
} 