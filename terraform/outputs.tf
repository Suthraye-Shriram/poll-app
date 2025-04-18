# GKE cluster info
output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_location" {
  value       = google_container_cluster.primary.location
  description = "GKE Cluster Location"
}

output "kubernetes_cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Endpoint"
  sensitive   = true
}

# Artifact Registry info
output "artifact_registry_repository" {
  value       = "${local.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.poll_app_repo.repository_id}"
  description = "Artifact Registry repository for Docker images"
}

# Database info
output "database_connection_name" {
  value       = google_sql_database_instance.main.connection_name
  description = "Cloud SQL instance connection name"
}

output "database_name" {
  value       = google_sql_database.database.name
  description = "Database name"
}

# Instructions for connecting to GKE and pushing images
output "gcloud_connect_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${local.project_id}"
  description = "Command to configure kubectl to connect to the cluster"
}

output "artifact_registry_command" {
  value       = "gcloud auth configure-docker ${local.region}-docker.pkg.dev"
  description = "Command to configure Docker to push to Artifact Registry"
}

output "image_tagging_example" {
  value       = <<EOF
  # Tag your images:
  docker tag poll-frontend:latest ${local.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.poll_app_repo.repository_id}/poll-frontend:v1
  docker tag poll-backend:latest ${local.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.poll_app_repo.repository_id}/poll-backend:v1
  
  # Push your images:
  docker push ${local.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.poll_app_repo.repository_id}/poll-frontend:v1
  docker push ${local.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.poll_app_repo.repository_id}/poll-backend:v1
  EOF
  description = "Example commands for tagging and pushing Docker images"
} 