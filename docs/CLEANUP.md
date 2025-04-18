# GCP Resources Cleanup Guide

This document provides instructions for safely tearing down all resources created for the Poll Application on GCP. Following these steps will help ensure that you don't leave behind any resources that might continue to incur charges.

## Prerequisites

Before proceeding with cleanup, ensure you have:

1. Backed up any important data from the database
2. Downloaded any logs or metrics you wish to keep
3. Confirmed with all team members that the resources can be destroyed

## Cleanup Steps

### 1. Delete Kubernetes Resources

First, delete all Kubernetes resources to ensure clean removal:

```bash
# Switch to the kubernetes directory
cd /path/to/poll-project-gcp/kubernetes

# Delete namespace (this will delete all resources in the namespace)
kubectl delete namespace poll-app

# Verify all pods are terminated
kubectl get pods -n poll-app
```

### 2. Destroy Terraform Resources

After Kubernetes resources are removed, use Terraform to destroy all infrastructure:

```bash
# Switch to the terraform directory
cd /path/to/poll-project-gcp/terraform

# Initialize Terraform (if needed)
terraform init

# Destroy all resources
terraform destroy

# When prompted, type 'yes' to confirm
```

The `terraform destroy` command will:

1. Delete the GKE cluster
2. Remove the Cloud SQL instance
3. Clean up networking components (VPC, subnets, etc.)
4. Remove IAM permissions and service accounts
5. Delete Secret Manager secrets
6. Remove Cloud Build triggers and configurations

### 3. Verify Cleanup

After Terraform completes the destruction process, verify that all resources have been removed:

```bash
# List any remaining GKE clusters
gcloud container clusters list

# Check for Cloud SQL instances
gcloud sql instances list

# Verify VPC networks have been removed
gcloud compute networks list
```

### 4. Manual Cleanup (If Needed)

Some resources might require manual cleanup:

1. **Cloud Storage Buckets**:
   ```bash
   # List buckets
   gsutil ls
   
   # Remove any project-related buckets
   gsutil rm -r gs://your-bucket-name
   ```

2. **Artifact Registry Repositories**:
   ```bash
   # List repositories
   gcloud artifacts repositories list
   
   # Delete repositories
   gcloud artifacts repositories delete poll-app-images --location=us-central1
   ```

3. **Cloud Build Histories**:
   These will be automatically cleaned up over time.

### 5. Disable APIs (Optional)

If you no longer need certain Google Cloud APIs for other projects:

```bash
# List enabled APIs
gcloud services list

# Disable specific APIs
gcloud services disable container.googleapis.com
gcloud services disable sqladmin.googleapis.com
gcloud services disable secretmanager.googleapis.com
```

## Final Verification

As a final step, check your Google Cloud Console to ensure all resources have been properly removed and that there are no unexpected resources still running.

## Important Notes

- The destruction process is irreversible. Make sure you have backups of any important data.
- It may take some time (up to 30 minutes) for all resources to be fully destroyed.
- Some resources may have dependencies that prevent immediate deletion. In such cases, Terraform will handle the correct deletion order.
- If any errors occur during the destruction process, address them before proceeding.

## Cost Verification

After cleanup, monitor your Google Cloud billing for 1-2 billing cycles to ensure no unexpected charges appear. 