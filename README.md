# Poll Application on GCP

A cloud-native polling application deployed on Google Cloud Platform using Kubernetes (GKE) and Terraform.

## Architecture

This project deploys a full-stack poll application with the following components:

- **Frontend**: Simple web interface for creating and voting on polls
- **Backend**: API service that handles poll data
- **Database**: Cloud SQL PostgreSQL database for data persistence
- **Infrastructure**: Managed with Terraform for easy deployment and management

## Accessing the Application

The application is available at:
- http://34.70.208.98

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
    └── CHALLENGES.md       # Common issues and solutions
```

## Deployment

For detailed deployment instructions, see [DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Architecture

For a comprehensive overview of the system architecture, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Troubleshooting

For common issues and their solutions, see [CHALLENGES.md](docs/CHALLENGES.md).

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