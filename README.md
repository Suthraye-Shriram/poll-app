# Poll Application on GCP Infrastructure

This repository contains a complete Terraform configuration for deploying a scalable and production-ready polling application on Google Cloud Platform (GCP).

## Project Architecture

The project deploys the following GCP resources:

1. **Google Kubernetes Engine (GKE)** cluster for container orchestration
2. **Cloud SQL PostgreSQL** database for data persistence
3. **Artifact Registry** repository for Docker image storage
4. **VPC Network** with private subnets and firewall rules
5. **Secret Manager** for securely storing database credentials
6. **Cloud Build** for continuous integration and deployment

## Application Components

- **Frontend**: A web UI for creating and participating in polls
- **Backend API**: Flask-based REST API for handling poll operations
- **Database**: PostgreSQL database for storing poll data

## Deployment Challenges and Solutions

During the deployment process, we encountered several challenges that required careful configuration:

### 1. GKE Node Pool Configuration Issues

**Challenge**: When applying Terraform changes, we encountered errors with the Google Kubernetes Engine node pool configuration. Specifically, the error indicated that at least one of the attributes like `node_version`, `image_type`, etc. must be specified when modifying an existing node pool.

**Solution**: 
- Added the required `kubelet_config` block with essential settings:
  - Set `cpu_manager_policy` to "none"
  - Configured `cpu_cfs_quota` to false
  - Set `pod_pids_limit` to 0
- Added resource labels to preserve configuration during updates
- Implemented a release channel for better version control

### 2. Duplicate Service API Enablement

**Challenge**: We had duplicate `google_project_service` resources for the Secret Manager API, which were present in both `main.tf` and `database.tf`.

**Solution**:
- Removed the duplicate declaration in `database.tf`
- Ensured proper dependency ordering using `depends_on` attributes

### 3. Security Concerns

**Challenge**: The initial configuration had overly permissive settings that could pose security risks.

**Solutions**:
- **Database Access**: Removed the `0.0.0.0/0` authorized networks configuration that allowed any IP to access the database
- **Firewall Rules**: Replaced overly permissive firewall rules with specific port-based rules:
  - Restricted TCP traffic to ports 443, 8080, 8443, 10250, 6443, 5432
  - Limited UDP traffic to ports 53 and 8472
- **Private Networking**: Configured GKE to use private networking with a NAT gateway for outbound traffic

### 4. Infrastructure Optimization

**Challenge**: Optimizing the infrastructure for cost while maintaining functionality.

**Solutions**:
- Used smallest available machine types (e2-micro)
- Configured minimal disk sizes
- Set up proper auto-scaling and management policies
- Utilized zonal deployments where appropriate for development environments

## CI/CD Pipeline with Cloud Build

We've implemented a robust CI/CD pipeline using Google Cloud Build to automate the building, testing, and deployment of application updates.

### Architecture

The CI/CD pipeline consists of the following components:
- **Source Code Repository**: GitHub repository containing application code
- **Cloud Build**: Service that automatically builds and deploys changes
- **Artifact Registry**: Storage for container images
- **Google Kubernetes Engine**: Deployment target for the application

### Workflow

1. Developers push code changes to GitHub repository
2. Cloud Build trigger detects changes and initiates the build process
3. The pipeline determines which services (frontend/backend) have changed
4. Only modified services are built and pushed to Artifact Registry
5. Kubernetes deployments are updated with the new image versions

### Key Features

- **Selective Building**: Only builds services that have code changes
- **Automatic Deployment**: Updates Kubernetes deployments automatically
- **Fast Feedback**: Provides build status directly in GitHub
- **Consistent Environments**: Ensures all environments use the same build process

### Setting Up the Pipeline

1. **Enable Cloud Build API**:
   ```
   gcloud services enable cloudbuild.googleapis.com
   ```

2. **Grant Necessary Permissions**:
   ```
   # Allow Cloud Build to access GKE
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
       --member="serviceAccount:YOUR_PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
       --role="roles/container.developer"
   ```

3. **Connect GitHub Repository**:
   - Go to Cloud Build → Triggers
   - Connect your GitHub repository
   - Create a new trigger that runs on push to main branch
   - Specify cloudbuild.yaml as the build configuration file

4. **Test the Pipeline**:
   - Make changes to either frontend or backend code
   - Push changes to the main branch
   - Monitor the build in Cloud Build console
   - Verify that the application updates in GKE

## Environment Setup

### Prerequisites

- Google Cloud SDK installed and configured
- Terraform CLI installed
- Docker installed (for building application images)

### Deployment Steps

1. **Initialize Terraform**:
   ```
   cd terraform
   terraform init
   ```

2. **Apply Terraform Configuration**:
   ```
   terraform apply
   ```

3. **Connect to GKE Cluster**:
   ```
   gcloud container clusters get-credentials poll-app-cluster --zone us-central1-a --project YOUR_PROJECT_ID
   ```

4. **Build and Push Docker Images**:
   ```
   # Configure Docker for Artifact Registry
   gcloud auth configure-docker us-central1-docker.pkg.dev
   
   # Build images
   docker build -t poll-frontend:latest ./poll-frontend
   docker build -t poll-backend:latest ./poll-backend-api
   
   # Tag images
   docker tag poll-frontend:latest us-central1-docker.pkg.dev/YOUR_PROJECT_ID/poll-app-images/poll-frontend:v1
   docker tag poll-backend:latest us-central1-docker.pkg.dev/YOUR_PROJECT_ID/poll-app-images/poll-backend:v1
   
   # Push images
   docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/poll-app-images/poll-frontend:v1
   docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/poll-app-images/poll-backend:v1
   ```

5. **Deploy Application to GKE**:
   ```
   kubectl apply -f kubernetes/
   ```

## Development Setup

For local development, a Docker Compose configuration is provided:

```
docker-compose up
```

This will start both the frontend and backend services with appropriate environment variables.

## Best Practices Implemented

1. **Separation of Concerns**: Different Terraform files for different resource types
2. **Security**: Private networking, minimal permissions, secure secret management
3. **Infrastructure as Code**: Complete automation of infrastructure provisioning
4. **Cost Optimization**: Appropriately sized resources for the application requirements
5. **Maintainability**: Well-structured code with clear naming conventions
6. **Continuous Integration/Deployment**: Automated build and deploy pipeline

## Future Enhancements

1. Add monitoring and alerting using Cloud Monitoring
2. Implement horizontal pod autoscaling based on metrics
3. Add backup and disaster recovery procedures
4. Implement CloudArmor for additional security 