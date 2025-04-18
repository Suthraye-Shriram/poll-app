#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables - change these as needed
PROJECT_ID="gen-lang-client-0646199746"
REGION="us-central1"
ZONE="us-central1-a"
REPO_NAME="poll-app-images"
CLUSTER_NAME="poll-app-cluster"
NAMESPACE="poll-app"

echo -e "${BLUE}Starting deployment for Poll App to GCP...${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}gcloud is not installed. Please install the Google Cloud SDK.${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker.${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install Terraform.${NC}"
    exit 1
fi

# Login to gcloud if needed
echo -e "${BLUE}Ensuring you're logged into Google Cloud...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo -e "${BLUE}Please login to Google Cloud:${NC}"
    gcloud auth login
fi

# Set the project
echo -e "${BLUE}Setting GCP project to $PROJECT_ID...${NC}"
gcloud config set project $PROJECT_ID

# Enable required services using gcloud
echo -e "${BLUE}Enabling required GCP services...${NC}"
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable secretmanager.googleapis.com

# Initialize Terraform
echo -e "${BLUE}Initializing Terraform...${NC}"
cd terraform
terraform init

# Apply Terraform configuration
echo -e "${BLUE}Applying Terraform configuration to create GCP resources...${NC}"
terraform apply -auto-approve

# Configure kubectl to connect to the cluster
echo -e "${BLUE}Configuring kubectl to connect to GKE cluster...${NC}"
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# Configure Docker to authenticate with Artifact Registry
echo -e "${BLUE}Configuring Docker to push to Artifact Registry...${NC}"
gcloud auth configure-docker $REGION-docker.pkg.dev

# Build and tag Docker images
echo -e "${BLUE}Building and tagging Docker images...${NC}"
cd ..

# Build and tag the frontend
echo -e "${BLUE}Building frontend image...${NC}"
cd poll-frontend
docker build -t poll-frontend:latest .
docker tag poll-frontend:latest $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/poll-frontend:v1
cd ..

# Build and tag the backend
echo -e "${BLUE}Building backend image...${NC}"
cd poll-backend-api
docker build -t poll-backend:latest .
docker tag poll-backend:latest $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/poll-backend:v1
cd ..

# Push images to Artifact Registry
echo -e "${BLUE}Pushing images to Artifact Registry...${NC}"
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/poll-frontend:v1
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/poll-backend:v1

# Apply Kubernetes configurations
echo -e "${BLUE}Applying Kubernetes configurations...${NC}"
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/database-secret.yaml
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/ingress.yaml

# Wait for deployments to be ready
echo -e "${BLUE}Waiting for deployments to be ready...${NC}"
kubectl wait --namespace=$NAMESPACE --for=condition=Available deployment --all --timeout=300s

# Get the Ingress external IP (may take a while to provision)
echo -e "${BLUE}Waiting for Ingress IP address (this may take a few minutes)...${NC}"
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
  echo "Waiting for external IP..."
  EXTERNAL_IP=$(kubectl get ingress poll-app-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo -e "${GREEN}Deployment successful!${NC}"
echo -e "${GREEN}Your application should be available at http://$EXTERNAL_IP once DNS propagates${NC}"
echo -e "${GREEN}Frontend URL: http://$EXTERNAL_IP${NC}"
echo -e "${GREEN}Backend API URL: http://$EXTERNAL_IP/api${NC}" 