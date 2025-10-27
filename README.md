# Hextris DevOps Challenge - Kubernetes CI/CD Pipeline

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Kubernetes](https://img.shields.io/badge/kubernetes-1.30-blue)
![Helm](https://img.shields.io/badge/helm-v3-blue)

## Overview

This project implements a production-ready CI/CD pipeline for deploying the Hextris web application to Kubernetes. The solution leverages infrastructure-as-code principles, containerization, and automated deployment pipelines aligned with modern DevOps practices.

**Key Technologies:** Terraform, Docker, Helm, Jenkins (Kubernetes agents), Kind

## Architecture

![Architecture Diagram](./docs/architecture-diagram.png)

*CI/CD Pipeline Architecture: The workflow shows the complete deployment lifecycle from code commit to production, with Jenkins running in TII's Kubernetes cluster orchestrating builds via Docker Hub and deployments to the Kind cluster.*

### Workflow Description

The CI/CD pipeline orchestrates the deployment through five main stages:

**1. Code Push (Developer → GitHub)**
Developers push code changes to the GitHub repository, which serves as the single source of truth for the application and infrastructure configuration.

**2. Pipeline Trigger (GitHub → Jenkins)**
GitHub webhook triggers the Jenkins pipeline running in TII's Kubernetes cluster. Jenkins spawns an ephemeral pod containing three isolated containers (Docker, Helm, kubectl) for the build process.

**3. Image Build & Push (Jenkins → Docker Hub)**
The Docker container builds the application image using the Dockerfile, tags it with the build number, and pushes it to Docker Hub registry for artifact storage and distribution.

**4. Kubernetes Deployment (Jenkins → Kind Cluster)**
The Helm container deploys the application to the Kind cluster using Helm charts. The deployment creates 2 replicas with configured resource limits, health probes, and auto-scaling capabilities.

**5. Image Pull (Docker Hub → Kind Cluster)**
During deployment, Kubernetes pulls the application image from Docker Hub to the local Kind cluster, creating the pods that serve the Hextris application.

**Infrastructure Provisioning:**
Terraform provisions the Kind cluster on the local VPS, creating the necessary infrastructure including the Kubernetes control plane, worker nodes, and ingress controller.

## Prerequisites

- VPS or local machine with Docker installed
- Docker Hub account
- GitHub account
- Access to TII Jenkins instance
- Terraform >= 1.5
- kubectl >= 1.28
- helm >= 3.13

## Project Structure

```
.
├── app/
│   ├── Dockerfile              # Multi-stage Nginx-based container
│   └── nginx/
│       └── default.conf        # Nginx configuration
├── helm/
│   └── hextris/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml  # 2 replicas with resource limits
│           ├── service.yaml     # ClusterIP service
│           ├── ingress.yaml     # External access configuration
│           ├── configmap.yaml   # Nginx config injection
│           └── hpa.yaml         # Horizontal Pod Autoscaler
├── jenkins/
│   ├── Jenkinsfile             # Declarative pipeline
│   └── pod-template.yaml       # Kubernetes agent configuration
├── terraform/
│   ├── main.tf                 # Kind cluster provisioning
│   ├── provider.tf
│   ├── variables.tf
│   └── outputs.tf
├── docs/
│   └── architecture-diagram.png # CI/CD architecture diagram
└── README.md
```

## Infrastructure Setup

### 1. Provision Kubernetes Cluster

The Kubernetes cluster is provisioned using Terraform with the Kind provider.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- Kind cluster with custom configuration
- Ingress controller (Nginx)
- Kubeconfig exported for external access

### 2. Verify Cluster

```bash
export KUBECONFIG=./hextris-cluster-config
kubectl cluster-info
kubectl get nodes
```

## Application Containerization

### Dockerfile Strategy

The application uses a multi-stage build optimized for production:

```dockerfile
FROM nginx:alpine
COPY hextris-src/ /usr/share/nginx/html/
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

Key features:
- Lightweight Alpine base (< 50MB)
- Static content served by Nginx
- Custom Nginx configuration for SPA routing

## Helm Chart Configuration

### Key Components

**Deployment:**
- 2 replicas for high availability
- Resource limits: CPU (200m), Memory (128Mi)
- Liveness and readiness probes
- Rolling update strategy

**Service:**
- Type: ClusterIP
- Port: 80
- Selector: app=hextris

**Ingress:**
- Nginx ingress controller
- Path-based routing
- Host: wildcard (*)

### Deployment

```bash
helm upgrade hextris ./helm/hextris \
  --install \
  --namespace default \
  --set image.repository=erwanb44300/hextris \
  --set image.tag=build-23
```

## CI/CD Pipeline

### Jenkins Configuration

The pipeline uses Kubernetes pod templates with three containers:

**Pod Template (`jenkins/pod-template.yaml`):**
- `docker`: Docker-in-Docker for image builds
- `helm`: Alpine/k8s for Helm deployments
- `kubectl`: Bitnami kubectl for verification

### Pipeline Stages

1. **Checkout**: Clone repository from GitHub
2. **Build Docker Image**: Build and tag with build number
3. **Push to Registry**: Push to Docker Hub with credentials
4. **Deploy with Helm**: Upgrade or install release with kubeconfig
5. **Verify Deployment**: Check rollout status and pod health

### Pipeline Execution

```groovy
pipeline {
    agent {
        kubernetes {
            yamlFile 'jenkins/pod-template.yaml'
        }
    }
    environment {
        REGISTRY = 'erwanb44300'
        IMAGE_NAME = 'hextris'
        BUILD_TAG = "build-${BUILD_NUMBER}"
        KUBECONFIG_PATH = "${WORKSPACE}/kubeconfig"
    }
    stages { ... }
}
```

Key features:
- Declarative pipeline syntax
- Kubeconfig injected via writeFile
- Workspace-based file sharing between containers
- Automated cleanup and Docker pruning

## Security Considerations

| Aspect | Implementation | Notes |
|--------|----------------|-------|
| Credentials | Docker Hub password via stdin | No plaintext in pipeline logs |
| Kubeconfig | Workspace-scoped, deleted post-deployment | Prevents credential leakage |
| TLS | Disabled for Kind cluster | Development only - enforce in production |
| Resource Limits | CPU: 200m, Memory: 128Mi | Prevents resource exhaustion attacks |
| Image Registry | Private Docker Hub repository | Controlled access to artifacts |

## Deployment Verification

After successful pipeline execution:

```bash
# Check deployment status
kubectl get deployments

# Verify pods
kubectl get pods -l app=hextris

# Check service
kubectl get svc hextris

# View ingress
kubectl get ingress
```

Expected output:
- 2 running pods
- ClusterIP service on port 80
- Ingress with localhost address

## Local Testing

```bash
# Port forward for local access
kubectl port-forward svc/hextris 8080:80

# Open browser
http://localhost:8080

# Verify application health
curl -I http://localhost:8080
# Expected: HTTP/1.1 200 OK
```

## Testing Strategy

### Pipeline Validation
- **Dockerfile lint**: Validated build multi-stage process
- **Helm lint**: `helm lint ./helm/hextris` (0 errors)
- **Deployment verification**: Automated rollout status check in pipeline

### Health Checks
```bash
# Liveness probe (configured in deployment)
curl http://<pod-ip>:80/

# Readiness probe validation
kubectl get pods -l app=hextris -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}'
# Expected: True True
```

### Load Testing (optional)
```bash
# Simple performance test
ab -n 1000 -c 10 http://localhost:8080/
```

## Troubleshooting

### Common Issues

**Pod not starting:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Helm deployment fails:**
```bash
helm list
helm rollback hextris <revision>
```

**Jenkins pipeline errors:**
- Verify kubeconfig validity
- Check container image availability
- Review Jenkins console output

## Technical Decisions

| Technology | Rationale |
|------------|-----------|
| **Kind** | Lightweight Kubernetes in Docker. Provides production-like environment with minimal overhead. Ideal for CI/CD testing and development workflows. |
| **Helm** | Industry-standard declarative deployments. Enables templating, versioning, and atomic rollbacks. Simplifies multi-environment management. |
| **Alpine Images** | Security-focused minimal base (~5MB vs 100MB+). Reduced attack surface and faster deployment times. |
| **Jenkins K8s Agents** | Ephemeral build agents with isolated containers. Resource-efficient and scalable. Eliminates agent maintenance overhead. |
| **Docker-in-Docker** | Enables Docker builds within Kubernetes pods. Isolated build environments prevent cache conflicts. |

## Continuous Improvement

| Enhancement | Priority | Impact |
|-------------|----------|--------|
| TLS certificates via Cert-Manager | High | Production security compliance |
| Prometheus + Grafana monitoring | High | Observability and SLA tracking |
| ArgoCD GitOps integration | Medium | Declarative deployments, drift detection |
| Trivy security scanning | Medium | CVE detection in container images |
| Blue-green deployments | Low | Zero-downtime releases |

## Repository

https://github.com/Erwan923/hextris-devops-challenge-erwan

## Author

Erwan B.  
DevOps Engineer  
Contact: erwan.brunet44300@gmail.com

## License

This project is created for the TII DevOps Engineer technical assessment.
