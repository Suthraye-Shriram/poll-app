# Enable Cloud Build API
resource "google_project_service" "cloudbuild" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Build to use GKE
resource "google_project_iam_member" "cloudbuild_gke" {
  project = local.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:131728914629@cloudbuild.gserviceaccount.com"
  depends_on = [google_project_service.cloudbuild]
}

# Allow Cloud Build to access Artifact Registry
resource "google_project_iam_member" "cloudbuild_artifactregistry" {
  project = local.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:131728914629@cloudbuild.gserviceaccount.com"
  depends_on = [google_project_service.cloudbuild]
}

# Allow Cloud Build to manage secrets
resource "google_project_iam_member" "cloudbuild_secretmanager" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:131728914629@cloudbuild.gserviceaccount.com"
  depends_on = [google_project_service.cloudbuild]
}

# Optional: If you want to create Cloud Build triggers with Terraform
# Uncomment this section and configure as needed

# resource "google_cloudbuild_trigger" "poll_app_trigger" {
#   name        = "poll-app-deploy"
#   description = "Build and deploy Poll App when code is pushed to main branch"
#   github {
#     owner = "Suthraye-Shriram"
#     name  = "poll-app"
#     push {
#       branch = "^main$"
#     }
#   }
#   
#   filename = "cloudbuild.yaml"
#   depends_on = [google_project_service.cloudbuild]
# }

# Output to help connect repository to Cloud Build manually
output "cloudbuild_setup_instructions" {
  value = <<-EOT
    To set up Cloud Build triggers, follow these steps:
    
    1. Visit the Cloud Build Triggers page:
       https://console.cloud.google.com/cloud-build/triggers?project=${local.project_id}
    
    2. Connect your GitHub repository
    
    3. Create a trigger with these settings:
       - Name: poll-app-deploy
       - Event: Push to a branch
       - Source: Your repository (https://github.com/Suthraye-Shriram/poll-app)
       - Branch: ^main$
       - Configuration: Repository
       - Location: /cloudbuild.yaml
    
    4. Click Create to finish setup
  EOT
} 