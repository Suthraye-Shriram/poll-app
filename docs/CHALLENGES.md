# 🛠️ Common Challenges and Solutions

This document outlines common challenges you might encounter when deploying the Poll Application on GCP and provides solutions to help troubleshoot these issues.

## Infrastructure Deployment Issues

### Terraform State Lock

**Problem**: Terraform operations fail with a state lock error.

**Solution**:
```bash
# Force unlock the state if you're sure no other operations are running
terraform force-unlock LOCK_ID
```

### API Enablement Failures

**Problem**: Terraform fails to enable required APIs.

**Solution**:
```bash
# Manually enable the required APIs
gcloud services enable container.googleapis.com compute.googleapis.com \
    servicenetworking.googleapis.com secretmanager.googleapis.com \
    sqladmin.googleapis.com cloudresourcemanager.googleapis.com \
    artifactregistry.googleapis.com

# Then retry Terraform apply
terraform apply
```

### GKE Node Pool Configuration

**Problem**: GKE node pool creation fails with errors about missing required attributes.

**Solution**:
```
# Ensure your node pool configuration includes required attributes
resource "google_container_node_pool" "primary_nodes" {
  # ... existing configuration ...
  
  # Add required attributes
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 100
    
    # Add service account if needed
    service_account = google_service_account.gke_sa.email
    
    # These oauth scopes are needed for proper node functionality
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
}
```

### Resource Quota Limits

**Problem**: Deployment fails due to resource quota limits.

**Solution**:
1. Check your current quotas:
   ```bash
   gcloud compute project-info describe --project YOUR_PROJECT_ID
   ```
2. Request quota increases in the GCP Console (IAM & Admin > Quotas)

## Database Issues

### Database Connection Errors

**Problem**: Backend service cannot connect to Cloud SQL.

**Solutions**:

1. **Check Cloud SQL Proxy**:
   ```bash
   # If using Cloud SQL Proxy, check its logs
   kubectl logs -l app=cloudsql-proxy -n poll-app
   ```

2. **Verify network connectivity**:
   ```bash
   # Ensure private service access is configured
   gcloud compute networks peerings list --network=poll-app-vpc
   ```

3. **Verify service account permissions**:
   ```bash
   # Make sure service account has Cloud SQL Client role
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:YOUR_SERVICE_ACCOUNT" \
     --role="roles/cloudsql.client"
   ```

### Database Initialization

**Problem**: Database schema initialization fails.

**Solution**:
```bash
# Connect to the database and manually initialize it
gcloud sql connect poll-app-db --user=postgres

# Then in the psql prompt:
CREATE DATABASE poll_app;
\c poll_app;
# Run your schema initialization scripts
```

## Kubernetes Deployment Issues

### Pod Scheduling Failures

**Problem**: Pods stay in a Pending state.

**Solutions**:

1. **Check node resources**:
   ```bash
   kubectl describe nodes
   ```

2. **Check PodDisruptionBudget**:
   ```bash
   kubectl get pdb -n poll-app
   ```

3. **Scale node pool if necessary**:
   ```bash
   gcloud container clusters resize poll-app-cluster \
     --node-pool=primary-nodes \
     --num-nodes=3 \
     --region=${GCP_REGION}
   ```

### Image Pull Errors

**Problem**: "ImagePullBackOff" or "ErrImagePull" errors.

**Solutions**:

1. **Verify Artifact Registry permissions**:
   ```bash
   # Make sure GKE service account can pull images
   gcloud artifacts repositories add-iam-policy-binding poll-app \
     --location=${GCP_REGION} \
     --member="serviceAccount:YOUR_GKE_SA" \
     --role="roles/artifactregistry.reader"
   ```

2. **Check image path**:
   ```bash
   # Correct format for Artifact Registry
   ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/poll-app/image-name:tag
   ```

### Service Account Issues

**Problem**: Workload Identity or service account issues.

**Solution**:
```bash
# Verify Workload Identity configuration
kubectl describe serviceaccount poll-app-sa -n poll-app

# Check the IAM binding
gcloud iam service-accounts get-iam-policy \
  ${GCP_PROJECT_ID}-compute@developer.gserviceaccount.com
```

## Networking Issues

### Ingress/LoadBalancer Problems

**Problem**: LoadBalancer service doesn't get an external IP.

**Solutions**:

1. **Check service status**:
   ```bash
   kubectl describe service frontend-service -n poll-app
   ```

2. **Verify firewall rules**:
   ```bash
   gcloud compute firewall-rules list \
     --filter="network:poll-app-vpc"
   ```

3. **Create necessary firewall rule**:
   ```bash
   gcloud compute firewall-rules create poll-app-allow-lb \
     --direction=INGRESS \
     --priority=1000 \
     --network=poll-app-vpc \
     --action=ALLOW \
     --rules=tcp:80,tcp:443 \
     --source-ranges=0.0.0.0/0 \
     --target-tags=gke-poll-app-cluster
   ```

### DNS Configuration

**Problem**: Custom domain not resolving.

**Solution**:
```bash
# Get Load Balancer IP
kubectl get service frontend-service -n poll-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Then update your DNS A record to point to this IP
```

## CI/CD Issues

### Cloud Build Failures

**Problem**: Cloud Build pipeline fails.

**Solutions**:

1. **Check build logs**:
   ```bash
   gcloud builds log BUILD_ID
   ```

2. **Verify service account permissions**:
   ```bash
   # Make sure Cloud Build service account has correct permissions
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:YOUR_PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
     --role="roles/container.developer"
   ```

3. **Fix cloudbuild.yaml**:
   Ensure your build steps have the correct syntax and dependencies.

## Security Issues

### Secret Management

**Problem**: Application can't access secrets.

**Solutions**:

1. **Verify Secret Manager access**:
   ```bash
   # Check IAM permissions
   gcloud projects get-iam-policy YOUR_PROJECT_ID \
     --format=json | grep secretmanager
   ```

2. **Check Kubernetes Secret**:
   ```bash
   kubectl describe secret poll-db-credentials -n poll-app
   ```

### VPC Security

**Problem**: Security vulnerabilities in VPC configuration.

**Solution**:
```bash
# Review and update firewall rules
gcloud compute firewall-rules list --filter="network:poll-app-vpc"

# Add more restrictive rules as needed
gcloud compute firewall-rules create poll-app-restrict-ssh \
  --direction=INGRESS \
  --priority=1000 \
  --network=poll-app-vpc \
  --action=DENY \
  --rules=tcp:22 \
  --source-ranges=0.0.0.0/0
```

## Performance Issues

### Application Slowness

**Problem**: Application performs poorly under load.

**Solutions**:

1. **Scale the application**:
   ```bash
   kubectl scale deployment backend-deployment --replicas=3 -n poll-app
   ```

2. **Adjust resource limits**:
   ```bash
   # Edit deployment to increase resources
   kubectl edit deployment backend-deployment -n poll-app
   ```

3. **Configure HPA (Horizontal Pod Autoscaler)**:
   ```bash
   kubectl autoscale deployment backend-deployment \
     --cpu-percent=70 \
     --min=2 \
     --max=10 \
     -n poll-app
   ```

### Database Performance

**Problem**: Database queries are slow.

**Solutions**:

1. **Upgrade database instance**:
   Modify terraform configuration for Cloud SQL instance to increase machine type or storage size.

2. **Add read replicas**:
   Add a read replica in Terraform configuration.

## Cost Optimization

### High Cloud Costs

**Problem**: GCP billing is higher than expected.

**Solutions**:

1. **Enable budget alerts** in GCP Console (Billing > Budgets & alerts > Create budget)

2. **Review resource usage**:
   ```bash
   # List running resources
   gcloud compute instances list
   gcloud container clusters list
   gcloud sql instances list
   
   # Resize or delete unused resources
   ```

3. **Use preemptible nodes** for non-critical workloads:
   ```hcl
   node_config {
     preemptible  = true
     machine_type = "e2-medium"
     # ...
   }
   ```

## General Troubleshooting Steps

1. **Check GCP Status**: Verify if there are any [GCP service disruptions](https://status.cloud.google.com/)

2. **Review activity logs**:
   ```bash
   gcloud logging read "resource.type=gke_cluster AND resource.labels.cluster_name=poll-app-cluster"
   ```

3. **Contact Support**: If you have a support package, open a case with GCP support

---

Remember to regularly update your Terraform modules and GCP SDKs to benefit from the latest features and security patches. 