# Poll Application on GCP

A cloud-native polling application deployed on Google Cloud Platform using Kubernetes (GKE) and Terraform.

## Architecture

This project deploys a full-stack poll application with the following components:

- **Frontend**: Simple web interface for creating and voting on polls
- **Backend**: API service that handles poll data
- **Database**: Cloud SQL PostgreSQL database for data persistence
- **Infrastructure**: Managed with Terraform for easy deployment and management

## Accessing the Application

The application can be accessed via the LoadBalancer's external IP address. To get the current IP:

```bash
kubectl get service poll-frontend -n poll-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then open the IP address in your browser: http://<EXTERNAL_IP>

## Repository Structure

```
poll-project-gcp/
├── app/                    # Application source code
│   ├── frontend/           # Frontend UI code
│   └── backend/            # Backend API service
├── kubernetes/             # Kubernetes deployment manifests
├── terraform/              # Terraform infrastructure code
└── docs/                   # Documentation
    ├── ARCHITECTURE.md     # Detailed architecture overview
    ├── DEPLOYMENT.md       # Deployment instructions
    ├── CHALLENGES.md       # Common issues and solutions
    └── LEARNINGS.md        # Key learnings and best practices
```

## Deployment

For detailed deployment instructions, see [DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Architecture

For a comprehensive overview of the system architecture, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Troubleshooting

For common issues and their solutions, see [CHALLENGES.md](docs/CHALLENGES.md).

## Learnings and Best Practices

For key insights and lessons learned from this project, see [LEARNINGS.md](docs/LEARNINGS.md).

## Development

### Prerequisites

- Google Cloud SDK
- Terraform
- kubectl
- Docker (for local development)

### Local Development

1. Clone the repository
2. Configure GCP credentials
3. Run `terraform init` to initialize Terraform
4. Deploy with `terraform apply`

## License

This project is licensed under the MIT License - see the LICENSE file for details. 