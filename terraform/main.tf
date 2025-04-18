terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "gen-lang-client-0646199746"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# Local variables for resource naming consistency
locals {
  project_id = "gen-lang-client-0646199746"
  region     = "us-central1"
  location   = "us-central1-a"
  
  # Resource naming
  gke_cluster_name    = "poll-app-cluster"
  vpc_name            = "poll-app-vpc"
  subnet_name         = "poll-app-subnet"
  db_instance_name    = "poll-app-db"
  artifact_repo_name  = "poll-app-images"
}

# Enable required GCP APIs
resource "google_project_service" "container" {
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# Create Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "poll_app_repo" {
  provider = google
  location = local.region
  repository_id = local.artifact_repo_name
  description = "Docker repository for Poll App images"
  format = "DOCKER"
  depends_on = [google_project_service.artifactregistry]
}

# IAM - Allow GKE service account to pull images from Artifact Registry
resource "google_artifact_registry_repository_iam_member" "gke_artifact_registry_access" {
  provider = google
  location = google_artifact_registry_repository.poll_app_repo.location
  repository = google_artifact_registry_repository.poll_app_repo.name
  role = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.gke_sa.email}"
  depends_on = [google_artifact_registry_repository.poll_app_repo]
}

# Create a service account for GKE nodes
resource "google_service_account" "gke_sa" {
  account_id   = "gke-poll-app-sa"
  display_name = "GKE Poll App Service Account"
}

# Grant necessary roles to the service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader"
  ])

  project = local.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
} 