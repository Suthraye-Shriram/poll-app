# 🏗️ Architecture Overview

This document provides a comprehensive overview of the Poll Application's architecture on Google Cloud Platform, detailing the infrastructure components, their relationships, and design decisions.

## Table of Contents
- [System Architecture Diagram](#system-architecture-diagram)
- [Infrastructure Components](#infrastructure-components)
- [Networking Architecture](#networking-architecture)
- [Security Architecture](#security-architecture)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring and Observability](#monitoring-and-observability)

## System Architecture Diagram

```
                                      ┌────────────────────┐
                                      │                    │
                                      │   Cloud Build      │
                                      │   (CI/CD Pipeline) │
                                      │                    │
                                      └──────────┬─────────┘
                                                 │
                                                 │ builds & deploys
                                                 ▼
┌─────────────────┐        ┌───────────────────────────────────────────┐
│                 │        │                                           │
│   Internet      │◄──────►│   Google Kubernetes Engine (GKE)          │
│                 │        │                                           │
└────────┬────────┘        │   ┌─────────────┐     ┌─────────────┐    │
         │                 │   │             │     │             │    │
         │                 │   │  Frontend   │     │  Backend    │    │
         └────────────────►│   │  Service    │◄───►│  Service    │    │
                           │   │  (LoadBal)  │     │             │    │
                           │   │             │     │             │    │
                           │   └─────────────┘     └──────┬──────┘    │
                           │                              │           │
                           └───────────────────────────────┼───────────┘
                                                           │
                                                           │ connects to
                                                           ▼
                                      ┌────────────────────────────────┐
                                      │                                │
                                      │   Cloud SQL                    │
                                      │   (PostgreSQL Database)        │
                                      │                                │
                                      └────────────────────────────────┘
                                                     │
                                                     │ stores secrets in
                                                     ▼
                                      ┌────────────────────────────────┐
                                      │                                │
                                      │   Secret Manager               │
                                      │   (Database Credentials)       │
                                      │                                │
                                      └────────────────────────────────┘
```

## Infrastructure Components

### 🌐 Google Kubernetes Engine (GKE)

**Configuration:**
- **Cluster Type:** Regional
- **Control Plane Version:** 1.27.3-gke.100
- **Node Pool:** `primary-nodes`
  - **Machine Type:** e2-small (2 vCPUs, 2GB memory)
  - **Disk Size:** 10GB
  - **Auto-scaling:** Enabled (1-3 nodes)
  - **Auto-repair:** Enabled
  - **Auto-upgrade:** Enabled

**Workloads:**
- **Frontend Deployment:**
  - Image: `us-central1-docker.pkg.dev/gen-lang-client-0646199746/poll-app/poll-frontend:latest`
  - Replicas: 1
  - Resources: Requests for 128Mi memory, 100m CPU
  - Service: LoadBalancer type exposing port 80

- **Backend Deployment:**
  - Image: `us-central1-docker.pkg.dev/gen-lang-client-0646199746/poll-app/poll-backend:latest`
  - Replicas: 1
  - Resources: Requests for 256Mi memory, 200m CPU
  - Service: ClusterIP type exposing port 5000
  - Environment: Connected to PostgreSQL database

### 🗄️ Cloud SQL (PostgreSQL)

**Configuration:**
- **Instance Type:** db-f1-micro (shared vCPU, 614MB memory)
- **Version:** PostgreSQL 14
- **Storage:** 10GB SSD
- **Network:** Private IP (accessible only from VPC)
- **High Availability:** Not enabled (dev/test environment)
- **Backups:** Automated daily backups enabled

### 🔐 Secret Manager

**Secrets Stored:**
- `poll-app-db-credentials`: JSON containing database username and password
- Format:
  ```json
  {
    "username": "pollapp",
    "password": "secure-password-here"
  }
  ```

### 📦 Artifact Registry

**Repositories:**
- `poll-app`: Docker repository for application images
  - `poll-frontend:latest`: Frontend application image
  - `poll-backend:latest`: Backend application image

## Networking Architecture

### 🔄 VPC and Subnets

**VPC Configuration:**
- **Name:** `poll-app-vpc`
- **Mode:** Auto-created VPC by GKE
- **Subnets:**
  - GKE Nodes subnet: Private IP range for GKE nodes
  - GKE Services subnet: IP range for Kubernetes services

### 🌍 External Access

**Ingress Configuration:**
- **Frontend Service Type:** LoadBalancer
  - Creates a Google Cloud Load Balancer
  - Provides external IP address for public access
  - Terminates TLS and routes traffic to frontend pods

**Traffic Flow:**
1. User traffic arrives at Google Cloud Load Balancer
2. Traffic is routed to the frontend service in GKE
3. Frontend service communicates with backend service over cluster network
4. Backend service communicates with Cloud SQL via private service connection

## Security Architecture

### 🔒 Network Security

**Firewall Rules:**
- Allow external traffic only to Load Balancer on ports 80/443
- Restrict direct access to GKE nodes
- Allow private communication between GKE and Cloud SQL

**Private Connectivity:**
- Cloud SQL accessible only via private IP
- No public IP for database access
- GKE to CloudSQL connection secured via VPC

### 👤 Identity and Access Management

**Service Accounts:**
- **GKE Nodes SA:** Limited permissions to Artifact Registry, Logging, and Monitoring
- **Cloud Build SA:** Permissions to deploy to GKE, push to Artifact Registry
- **Cloud SQL SA:** Managed by Google, used for backups and maintenance

**Secrets Management:**
- Database credentials stored in Secret Manager
- Secret Manager API used by application to retrieve credentials
- Kubernetes secrets created from Secret Manager for pod access

## CI/CD Pipeline

### 🚀 Cloud Build

**Build Triggers:**
- **Source:** GitHub repository
- **Event:** Push to main branch
- **Configuration:** `cloudbuild.yaml`

**Pipeline Steps:**
1. Build frontend and backend Docker images
2. Push images to Artifact Registry
3. Deploy to GKE using kubectl
4. Update image tags in Kubernetes deployments

### 📊 Versioning Strategy

**Image Tags:**
- Latest tag for current development state
- Commit SHA tags for immutable historical versions
- Release tags for milestone versions (e.g., v1.0.0)

## Monitoring and Observability

### 📝 Logging

**Components:**
- Cloud Logging integration with GKE
- Application logs streamed to Cloud Logging
- Log-based metrics for error rates and API usage

### 📈 Monitoring

**Metrics Collected:**
- GKE node and pod metrics
- Cloud SQL performance metrics
- Application-specific metrics via custom logging

**Alerts:**
- Notification channels configured for critical alerts
- High CPU/memory usage alerts
- Error rate threshold alerts

---

This architecture provides a scalable, secure, and maintainable foundation for the Poll Application on Google Cloud Platform. The design prioritizes security, separation of concerns, and follows cloud-native best practices. 