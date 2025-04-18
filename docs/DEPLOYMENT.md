# 🚀 Deployment Guide

This guide provides step-by-step instructions for deploying the Poll Application on Google Cloud Platform (GCP).

## Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Application Deployment](#application-deployment)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting the deployment process, ensure you have the following:

1. **GCP Account** with billing enabled
2. **Project created** in GCP Console
3. **Local Development Environment** with:
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured
   - [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
   - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
   - [Git](https://git-scm.com/downloads)

4. **Required Permissions**:
   - Owner or Editor role on the GCP project
   - Or specific roles:
     - Compute Admin
     - Kubernetes Engine Admin
     - Service Account User
     - Cloud SQL Admin
     - Secret Manager Admin

## Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/poll-project-gcp.git
cd poll-project-gcp
```

### 2. Configure Google Cloud SDK

```bash
# Configure gcloud with your project
gcloud init
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com \
    compute.googleapis.com \
    servicenetworking.googleapis.com \
    secretmanager.googleapis.com \
    sqladmin.googleapis.com \
    cloudresourcemanager.googleapis.com \
    artifactregistry.googleapis.com
```

### 3. Set Environment Variables

Create a `.env` file in the root directory:

```bash
# Create and edit .env file
cat > .env << 'EOF'
export GCP_PROJECT_ID=YOUR_PROJECT_ID
export GCP_REGION=us-central1
export GCP_ZONE=us-central1-a
export POLL_APP_DB_PASSWORD=$(openssl rand -base64 16)
EOF

# Load environment variables
source .env
```

## Infrastructure Deployment

The infrastructure is managed using Terraform, which creates all required GCP resources.

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Configure Terraform Variables

Create a `terraform.tfvars` file:

```bash
cat > terraform.tfvars << EOF
project_id          = "${GCP_PROJECT_ID}"
region              = "${GCP_REGION}"
zone                = "${GCP_ZONE}"
db_password         = "${POLL_APP_DB_PASSWORD}"
EOF
```

### 3. Validate Terraform Configuration

```bash
terraform validate
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply -auto-approve
```

This process takes approximately 10-15 minutes to complete. It creates:
- GKE Cluster
- Cloud SQL PostgreSQL instance
- Secret Manager entries
- Networking components
- Service accounts

## Application Deployment

After the infrastructure is provisioned, deploy the application to GKE.

### 1. Get Cluster Credentials

```bash
gcloud container clusters get-credentials poll-app-cluster --region ${GCP_REGION}
```

### 2. Deploy the Application

You can deploy the application either using Cloud Build or manually:

#### Option A: Using Cloud Build (Recommended)

```bash
# Trigger the Cloud Build pipeline
gcloud builds submit --config cloudbuild.yaml
```

#### Option B: Manual Deployment

```bash
# Build and push Docker images
cd ../app
docker build -t ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/poll-app/poll-frontend:latest ./frontend
docker build -t ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/poll-app/poll-backend:latest ./backend

docker push ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/poll-app/poll-frontend:latest
docker push ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/poll-app/poll-backend:latest

# Deploy to Kubernetes
cd ../kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

## Verification

### 1. Check Deployment Status

```bash
# Verify pods are running
kubectl get pods -n poll-app

# Verify services
kubectl get services -n poll-app
```

### 2. Get the Application URL

```bash
export FRONTEND_IP=$(kubectl get service frontend-service -n poll-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://${FRONTEND_IP}"
```

### 3. Test the Application

Open the URL in a web browser to verify the application is working correctly.

## Troubleshooting

### Common Issues and Solutions

#### Database Connection Issues

If the backend cannot connect to the database:

1. Verify database credentials:

```bash
# Check secret exists
kubectl get secret poll-db-credentials -n poll-app

# Verify database service
gcloud sql instances describe poll-app-db --format="value(connectionName)"
```

2. Check backend logs:

```bash
kubectl logs -l app=backend -n poll-app
```

#### Pod Scheduling Issues

If pods remain in Pending state:

```bash
# Check pod status
kubectl describe pod -l app=backend -n poll-app

# Check node resources
kubectl describe nodes
```

#### Load Balancer Issues

If the frontend service doesn't get an external IP:

```bash
# Check service status
kubectl describe service frontend-service -n poll-app

# Check firewall rules
gcloud compute firewall-rules list --filter="network:poll-app-vpc"
```

### Useful Commands

Reset the application:

```bash
# Delete and recreate deployments
kubectl delete -f kubernetes/
kubectl apply -f kubernetes/
```

Check cluster status:

```bash
gcloud container clusters describe poll-app-cluster --region ${GCP_REGION}
```

## Cleanup

To delete all resources and avoid incurring charges:

```bash
# Return to Terraform directory
cd terraform

# Destroy infrastructure
terraform destroy -auto-approve
```

---

For additional support, please refer to the [CHALLENGES.md](./CHALLENGES.md) document which outlines common issues and solutions encountered during deployment. 