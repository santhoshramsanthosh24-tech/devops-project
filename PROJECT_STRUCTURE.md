# Project Structure Documentation

## Directory Layout

```
Devops_project/
├── app/                              # Application Source Code
│   ├── src/
│   │   └── index.js                 # Main Express server with health checks
│   ├── package.json                 # Node.js dependencies
│   └── package-lock.json           # Dependency lock file
│
├── docker/                           # Docker Configuration
│   ├── Dockerfile                   # Multi-stage production build
│   ├── Dockerfile.dev              # Development Dockerfile
│   ├── docker-compose.yml          # Complete stack (app, jenkins, prometheus, etc)
│   └── prometheus.yml              # Prometheus scrape configuration
│
├── jenkins/                          # CI/CD Pipeline Configuration
│   ├── Jenkinsfile                 # Main pipeline (15 stages)
│   ├── Jenkinsfile.groovy         # Groovy utilities
│   ├── jenkins-init.groovy        # Jenkins initialization
│   └── plugins.txt                # Required plugins list
│
├── kubernetes/                       # Container Orchestration
│   ├── deployment.yaml             # Kubernetes Deployment (3 replicas)
│   ├── service.yaml                # Kubernetes Service (LoadBalancer)
│   ├── ingress.yaml                # Ingress routing
│   ├── configmap.yaml              # Configuration management
│   └── rbac.yaml                   # Security (ServiceAccount, RBAC)
│
├── tests/                            # Test Suites
│   ├── unit-tests/
│   │   └── app.test.js            # Unit tests
│   └── integration-tests/
│       └── api.test.js            # Integration tests
│
├── scripts/                          # Automation Scripts
│   ├── setup.sh                    # First-time setup automation
│   ├── deploy.sh                   # Kubernetes deployment script
│   ├── health-check.sh             # Service health verification
│   └── rollback.sh                 # Deployment rollback
│
├── .env.example                      # Environment template
├── .gitconfig                        # Git configuration
├── .dockerignore                     # Docker build exclusions
├── .gitignore                        # Git exclusions
├── README.md                         # Main documentation
├── HOW_TO_RUN.md                    # Getting started guide
└── ARCHITECTURE.md                  # System architecture

```

---

## What Each Directory Does

### `app/` - Your Application Code
- **Purpose**: Contains the actual Node.js application
- **Key Files**:
  - `src/index.js` - Express server with multiple endpoints
  - `package.json` - Defines dependencies and scripts
- **Endpoints**:
  - `GET /` - Root API
  - `GET /health` - Health check (for load balancers)
  - `GET /ready` - Readiness probe (for Kubernetes)
  - `GET /metrics` - Prometheus metrics
  - `GET /api/status` - Application status
  - `GET /api/deployment-info` - Deployment details

### `docker/` - Containerization
- **Purpose**: Docker configuration for building container images
- **Key Files**:
  - `Dockerfile` - Multi-stage build optimizes image size
  - `docker-compose.yml` - Runs entire stack locally:
    - Application (Node.js)
    - Jenkins (CI/CD)
    - Prometheus (Metrics)
    - Grafana (Dashboards)
    - PostgreSQL (Database)
    - PgAdmin (Database UI)
    - Docker Registry (Private)

### `jenkins/` - CI/CD Pipeline
- **Purpose**: Automates the entire deployment pipeline
- **Key Files**:
  - `Jenkinsfile` - 15-stage pipeline:
    1. Initialize
    2. Checkout (Git)
    3. Build
    4. Unit Tests
    5. Code Quality
    6. Security Scan
    7. Docker Build
    8. Container Tests
    9. Docker Push
    10. Deploy Dev
    11. Smoke Tests
    12. Deploy Staging
    13. Deploy Production
    14. Integration Tests
    15. Performance Tests

### `kubernetes/` - Production Deployment
- **Purpose**: Kubernetes manifests for production environments
- **Key Files**:
  - `deployment.yaml` - 3 replicas with auto-scaling
  - `service.yaml` - LoadBalancer service
  - `ingress.yaml` - HTTP routing
  - `rbac.yaml` - Security and permissions
  - `configmap.yaml` - Configuration data

### `tests/` - Quality Assurance
- **Purpose**: Automated tests at different stages
- **Types**:
  - Unit tests - Individual component testing
  - Integration tests - Multiple components together
  - Smoke tests - Quick sanity checks
  - Performance tests - Load and stress testing

### `scripts/` - Automation
- **Purpose**: Helper scripts for common tasks
- **Usage**:
  - `setup.sh` - One-command setup
  - `deploy.sh` - Kubernetes deployment
  - `health-check.sh` - Verify all services
  - `rollback.sh` - Rollback to previous version

---

## File Functions

### Core Application Files

| File | Function |
|------|----------|
| `app/src/index.js` | Express server, health checks, metrics |
| `app/package.json` | Dependencies, scripts, metadata |
| `docker/Dockerfile` | Build production container image |
| `docker/docker-compose.yml` | Orchestrate local development |
| `jenkins/Jenkinsfile` | Define CI/CD pipeline stages |

### Kubernetes/Infrastructure

| File | Function |
|------|----------|
| `kubernetes/deployment.yaml` | Pod specification, replicas, health checks |
| `kubernetes/service.yaml` | Network service, LoadBalancer |
| `kubernetes/ingress.yaml` | HTTP routing, TLS termination |
| `kubernetes/rbac.yaml` | Service accounts, permissions |
| `kubernetes/configmap.yaml` | Configuration data for apps |

### Configuration Files

| File | Function |
|------|----------|
| `.env.example` | Environment variable template |
| `.gitignore` | Tell Git what to skip |
| `.dockerignore` | Tell Docker what to skip |
| `.gitconfig` | Git settings |

---

## Data Flow

```
Developer commits code to Git
        ↓
GitHub webhook triggers Jenkins
        ↓
Jenkins runs Jenkinsfile pipeline
        ↓
[Build] npm install && build
        ↓
[Test] npm test && test:integration
        ↓
[Quality] Code scanning, lint checks
        ↓
[Docker] docker build creates image
        ↓
[Push] Image pushed to registry
        ↓
[Deploy] kubectl applies Kubernetes manifests
        ↓
[Verify] Smoke tests validate deployment
        ↓
Application running in production
```

---

## Environment Variables

Key variables used throughout the project:

```bash
# .env Files
NODE_ENV=production          # Application mode
PORT=3000                   # Server port
LOG_LEVEL=info             # Logging level
DOCKER_USERNAME=myuser     # Docker credentials
DOCKER_PASSWORD=mypass     # Docker credentials
KUBE_NAMESPACE=default     # Kubernetes namespace
DEPLOYMENT_ENV=production  # Deployment environment
```

---

## Service Ports

| Service | Port | URL |
|---------|------|-----|
| Application | 3000 | http://localhost:3000 |
| Jenkins | 8080 | http://localhost:8080 |
| Prometheus | 9090 | http://localhost:9090 |
| Grafana | 3001 | http://localhost:3001 |
| PgAdmin | 5050 | http://localhost:5050 |
| PostgreSQL | 5432 | localhost:5432 |
| Docker Registry | 5000 | localhost:5000 |

---

## Key Concepts

### Multi-Stage Docker Build
Reduces final image size by separating build and runtime:
```Dockerfile
FROM node:18 AS builder    # Stage 1: Build
RUN npm install           # Large, discarded

FROM node:18              # Stage 2: Runtime
COPY --from=builder ...   # Only copy essential files
```

### CI/CD Pipeline Stages
Jenkinsfile has 15 automated stages ensuring code quality and safe deployment.

### Kubernetes Probes
- **Liveness**: Restart pods that are unhealthy
- **Readiness**: Remove unhealthy pods from load balancer
- **Startup**: Give app time to initialize

### Infrastructure as Code
All infrastructure (Kubernetes, Docker) is version controlled and reproducible.

---

## Important Notes

1. **Security**: Kubernetes RBAC is configured but review for your use case
2. **Database**: PostgreSQL included in docker-compose, schema needs initialization
3. **Registry**: Docker Registry included locally, use Docker Hub/ECR for production
4. **Credentials**: Store in Kubernetes Secrets, not in plaintext
5. **Scaling**: Kubernetes deployment configured for 3 replicas, adjust as needed

---

**For quick start**: See `HOW_TO_RUN.md`  
**For detailed architecture**: See `README.md`
