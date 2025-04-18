# Poll Application on Google Cloud Platform

A production-ready, scalable polling application deployed on Google Cloud Platform (GCP) with automated CI/CD pipeline.

![GCP Poll App Architecture](https://mermaid.ink/img/pako:eNqFkstugzAQRX9l5FWrJGRFWoioklMpTVOlSbtpsxJibAdiGmw5Jg-V_HtNQh5N01R4Y-bO8dxr6AOnigFneWFQCsq5RXnmLbHIuLOm0iptqFJGSRUeC26Zfvbl1LLCFQs9F-m7Vhoj5wY3SBsntQY5jDpwwQ1aFE1HkQ7WTtbCVJ4WWnNXSj2IUiXwUlq0D9UflXf-OxSxXvXl64I7a1Ue6UFfSNf8v2qJbXtCQjAHXjiJGBki6gPM34pIrJC5gP0eUjI9n4AwyXTOYT-_QUw2FBN6GzEy5HQZTsZw8TCbQsJoOMXEcD5PnuZr8vxInEUinXwfC6mMnTa87cbzYNM1PVIpUfAR3Tf0vCbwRVPYsVfKQJHtrQNaM9k0lYGZl5A98ixI8tOT7zgbmXWG4GCEsE1k1u3FnRirzVRgOgxXrLJJurA7gAazcGQXz5cTX2Fvjfksi9wyzrKqhJhvF-_pANL5ZR4avkoxaBu0_QFfJdcr)

## Project Description

This project implements a web-based polling application where users can create polls, vote, and view results. The application is deployed on Google Cloud Platform using a robust DevOps infrastructure.

### Key Features

- **Frontend**: Simple, responsive UI for creating and participating in polls
- **Backend API**: RESTful API for handling poll data operations
- **Database**: PostgreSQL database for persistent storage
- **Infrastructure as Code**: Complete GCP infrastructure defined using Terraform
- **Containerization**: Docker containers for consistent deployments
- **Orchestration**: Kubernetes for scaling and management
- **CI/CD Pipeline**: Automated build and deployment using Cloud Build

## Architecture

### Infrastructure Components

- **Google Kubernetes Engine (GKE)**: Manages containerized application deployment
- **Cloud SQL (PostgreSQL)**: Provides managed database services
- **Artifact Registry**: Stores Docker container images
- **Secret Manager**: Securely stores database credentials
- **VPC Network**: Provides private networking with appropriate firewall rules
- **Cloud Build**: Automates CI/CD workflow

### Application Components

- **Frontend**: Nginx-served static HTML/CSS/JS
- **Backend**: Flask API with PostgreSQL database
- **Network**: Private VPC with appropriate subnets and firewall rules

### Workflow

1. Developers push code to GitHub
2. Cloud Build trigger detects changes
3. Docker images are built and pushed to Artifact Registry
4. Kubernetes deployments are updated with new image versions
5. Application scales automatically based on demand

## Tech Stack

### Cloud & Infrastructure
- Google Cloud Platform (GCP)
- Terraform for Infrastructure as Code
- Google Kubernetes Engine (GKE)
- Cloud SQL for PostgreSQL
- Artifact Registry
- Secret Manager
- Virtual Private Cloud (VPC)
- Cloud Build CI/CD

### Development & Deployment
- Docker for containerization
- Kubernetes for orchestration
- Git/GitHub for version control
- Bash scripting

### Application
- Frontend: HTML, CSS, JavaScript
- Backend: Python with Flask
- Database: PostgreSQL

## Prerequisites

Before you begin, ensure you have the following installed:

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Git](https://git-scm.com/downloads)

## Setup Instructions

### 1. GCP Project Setup

1. Create a new GCP project or use an existing one
2. Enable billing for the project
3. Set up your gcloud CLI:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Clone the Repository

```bash
git clone https://github.com/Suthraye-Shriram/poll-app.git
cd poll-app
```

### 3. Infrastructure Deployment

1. Initialize Terraform:

```bash
cd terraform
terraform init
```

2. Apply the Terraform configuration:

```bash
terraform apply
```

3. Note the outputs, which include commands to connect to GKE and other resources

### 4. Application Deployment

#### Option 1: Manual Deployment

1. Configure Docker for Artifact Registry:

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

2. Build and push Docker images:

```bash
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

3. Connect to the GKE cluster:

```bash
gcloud container clusters get-credentials poll-app-cluster --zone us-central1-a --project YOUR_PROJECT_ID
```

4. Apply Kubernetes manifests:

```bash
kubectl apply -f kubernetes/
```

#### Option 2: Automated Deployment (CI/CD)

1. Set up Cloud Build trigger (already configured in the repository):
   - Go to Cloud Build section in GCP Console
   - Connect your GitHub repository
   - Create a trigger that watches the main branch
   - Use the cloudbuild.yaml file in the repository

2. Make code changes and push to GitHub:
   - The CI/CD pipeline will automatically build and deploy your changes

### 5. Accessing the Application

1. Get the external IP of the frontend service:

```bash
kubectl get service poll-frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

2. Access the application in your browser using this IP address

## CI/CD Pipeline

The project uses Cloud Build for continuous integration and deployment:

1. **Trigger**: Changes to the main branch automatically trigger the build process
2. **Smart Building**: The pipeline intelligently builds only the services that have changed
3. **Image Storage**: Built Docker images are stored in Artifact Registry
4. **Deployment**: Kubernetes deployments are automatically updated with new image versions

## Development Workflow

### Local Development

Use Docker Compose for local development:

```bash
docker-compose up
```

This starts both frontend and backend services on your local machine.

### Making Changes

1. Develop and test locally
2. Commit and push changes to GitHub
3. Cloud Build automatically builds and deploys the changes
4. Monitor build status in the Cloud Build console

## Challenges and Solutions

During development, we encountered and solved several challenges:

### GKE Node Pool Configuration

**Challenge**: Node pool updates would fail due to immutable field modifications.
**Solution**: Added required kubelet configuration and implemented a release channel for better version control.

### Security Concerns

**Challenge**: Initial configurations had overly permissive access controls.
**Solution**: Implemented proper security practices:
- Removed public database access
- Added specific firewall rules
- Configured private GKE networking
- Implemented Secret Manager for credentials

### Infrastructure Optimization

**Challenge**: Balancing cost vs. performance.
**Solution**: 
- Used smallest viable machine types
- Configured auto-scaling
- Implemented zonal deployments for development

## Future Improvements

1. **Monitoring and Logging**: Implement Cloud Monitoring and Logging for better observability
2. **Horizontal Pod Autoscaling**: Configure autoscaling based on metrics
3. **High Availability**: Implement multi-zone or multi-region deployment
4. **Backup and Disaster Recovery**: Implement automated backups and recovery procedures
5. **Security Hardening**: Implement Cloud Armor for additional protection
6. **Custom Domain and SSL**: Add custom domain with managed SSL certificates

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure service accounts have the correct permissions
2. **Connection Errors**: Check network settings and firewall rules
3. **Deployment Failures**: Verify Kubernetes configurations and container health

### Getting Help

If you encounter issues:
1. Check the logs in Cloud Build, GKE, and Cloud SQL
2. Review the Terraform state and outputs
3. Open an issue in the GitHub repository

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Cloud Platform documentation
- Terraform and Kubernetes communities
- All contributors to this project 