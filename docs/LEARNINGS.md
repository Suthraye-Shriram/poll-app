# Key Learnings from GCP Poll Application Project

This document captures key learnings, best practices, and insights gained throughout the development and deployment of the Poll Application on Google Cloud Platform.

## Infrastructure as Code (IaC) Learnings

1. **Terraform State Management**
   - Storing state remotely in GCS buckets proved essential for team collaboration
   - Using state locking prevented concurrent modifications that could cause conflicts
   - Breaking Terraform code into logical modules improved maintainability

2. **API Management**
   - Pre-enabling required APIs in a dedicated Terraform resource block prevents cascading failures
   - Some APIs have dependencies that need to be enabled in a specific order
   - Using `disable_on_destroy = false` prevents accidental API disablement during teardown

3. **Resource Naming Conventions**
   - Consistent naming across resources simplified management and troubleshooting
   - Including environment indicators (dev/prod) in resource names aided identification
   - Using descriptive names improved clarity in logs and monitoring

## Database Learnings

1. **Cloud SQL Configuration**
   - Private IP configuration required proper VPC setup but improved security
   - Connection pooling significantly improved performance under load
   - Automated backups were essential for data integrity

2. **Secret Management**
   - Secret Manager integration required careful IAM permission setup
   - Using Secret Manager for database credentials improved security posture
   - Rotating secrets periodically is essential but requires application awareness

## Kubernetes Deployment Learnings

1. **GKE Configuration**
   - Separately managed node pools provided flexibility for scaling different workloads
   - Regional clusters increased availability but at higher cost
   - Node auto-provisioning helped manage fluctuating workloads efficiently

2. **Resource Requests and Limits**
   - Properly configured resource requests improved pod scheduling
   - Setting appropriate limits prevented resource contention
   - CPU:Memory ratios needed adjustment based on actual application behavior

3. **Service Configuration**
   - Internal services for backend improved security
   - LoadBalancer for frontend simplified external access
   - Service mesh consideration for future scaling

## CI/CD Pipeline Learnings

1. **Cloud Build Efficiency**
   - Conditional builds based on changed directories improved pipeline efficiency
   - Storing build artifacts in Artifact Registry provided better versioning
   - Build timeouts needed adjustment for larger builds

2. **Deployment Strategies**
   - Rolling updates minimized downtime during deployments
   - Considering blue/green deployments for future zero-downtime upgrades
   - Automated rollbacks based on health checks would improve reliability

## Security Learnings

1. **Principle of Least Privilege**
   - Creating service accounts with minimal permissions improved security posture
   - Regular IAM audits helped identify and remove unnecessary permissions
   - Using workload identity for GKE reduced need for service account keys

2. **Network Security**
   - VPC-native clusters improved network performance and security
   - Private Google Access enabled services to access Google APIs without public IPs
   - Firewall rules required careful planning to balance security and functionality

## Monitoring and Logging

1. **Observability Strategy**
   - Cloud Monitoring dashboards provided valuable insights into application health
   - Log-based metrics helped identify patterns in application behavior
   - Setting up appropriate alerts prevented many potential outages

2. **Cost Management**
   - Regular billing reports helped identify cost optimization opportunities
   - Right-sizing resources based on actual usage patterns reduced waste
   - Using committed use discounts for predictable workloads reduced costs

## Future Improvements

1. **Performance Optimization**
   - Implementing CDN for static assets would improve frontend performance
   - Database query optimization based on actual usage patterns
   - Considering Memorystore (Redis) for caching frequently accessed data

2. **Reliability Enhancements**
   - Implementing multi-region deployment for higher availability
   - Setting up disaster recovery procedures with documented RTO/RPO
   - Chaos engineering practices to identify weak points

3. **Developer Experience**
   - Streamlining local development environment setup
   - Improving CI/CD feedback loops for faster iteration
   - Enhancing documentation with more examples and tutorials

## Conclusion

Building and deploying the Poll Application on GCP provided valuable insights into cloud-native application development, infrastructure management, and DevOps practices. These learnings will inform future projects and help establish best practices for cloud deployments. 