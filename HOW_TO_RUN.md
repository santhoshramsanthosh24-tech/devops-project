# HOW TO RUN & GETTING STARTED GUIDE

## 📋 Quick Reference

This guide explains how to run the complete DevOps CI/CD project locally and in production.

---

## 🚀 Method 1: Docker Compose (Fastest - Recommended for Learning)

### Prerequisites
- Docker Desktop installed
- Git installed
- 4GB+ RAM available
- Port 3000, 8080, 9090 available

### Step-by-Step: Local Setup with Docker Compose

```bash
# 1. Navigate to project directory
cd e:\data engennering\Devops_project

# 2. Build the Docker image
docker build -f docker/Dockerfile -t devops-cicd-app:latest .

# 3. Start all services
docker-compose -f docker/docker-compose.yml up -d

# 4. Verify services are running
docker ps

# 5. Check application health
curl http://localhost:3000/health

# 6. View logs
docker-compose -f docker/docker-compose.yml logs -f
```

### Accessing Services

After Docker Compose starts:

| Service | URL | Purpose |
|---------|-----|---------|
| Application | http://localhost:3000 | Your Node.js app |
| Jenkins | http://localhost:8080 | CI/CD Pipeline |
| Prometheus | http://localhost:9090 | Metrics Collection |
| Grafana | http://localhost:3001 | Dashboards |
| PgAdmin | http://localhost:5050 | Database UI |
| Registry | http://localhost:5000 | Docker Images |

### Get Jenkins Admin Password
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Stop All Services
```bash
docker-compose -f docker/docker-compose.yml down
```

---

## 🔧 Method 2: Jenkins Pipeline (Production Simulation)

### Step 1: Start Jenkins Container
```bash
docker run -d --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:latest

# Get initial password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 2: Configure Jenkins
1. Open http://localhost:8080
2. Enter the initial admin password
3. Install suggested plugins
4. Create admin user
5. Create new item → Pipeline

### Step 3: Create Pipeline Job
1. Job Name: `DevOps-CI-CD`
2. Pipeline section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/YOUR_USER/devops-project`
   - Branch: `*/main`
   - Script Path: `jenkins/Jenkinsfile`

### Step 4: Configure Build Triggers
- ✓ GitHub hook trigger for GITScm polling
- ✓ Poll SCM: `H/5 * * * *` (every 5 minutes)

### Step 5: Build the Pipeline
1. Click "Build Now"
2. Watch the pipeline execute through all stages
3. View console output for logs

---

## ☸️ Method 3: Kubernetes Deployment (Enterprise)

### Prerequisites
- kubectl configured
- Active Kubernetes cluster (minikube, Docker Desktop K8s, or cloud)
- Docker image pushed to registry

### Step-by-Step: Deploy to Kubernetes

```bash
# 1. Create namespace
kubectl create namespace devops-prod

# 2. Apply manifests
kubectl apply -f kubernetes/configmap.yaml -n devops-prod
kubectl apply -f kubernetes/rbac.yaml -n devops-prod
kubectl apply -f kubernetes/deployment.yaml -n devops-prod
kubectl apply -f kubernetes/service.yaml -n devops-prod
kubectl apply -f kubernetes/ingress.yaml -n devops-prod

# 3. Check deployment status
kubectl get deployments -n devops-prod
kubectl get pods -n devops-prod
kubectl get services -n devops-prod

# 4. Port forward to access locally
kubectl port-forward svc/devops-app-service 3000:80 -n devops-prod

# 5. Check logs
kubectl logs -f deployment/devops-app -n devops-prod

# 6. Describe deployment for troubleshooting
kubectl describe deployment devops-app -n devops-prod
```

---

## 🎯 Method 4: Automated Setup (One Command)

### Using the Setup Script

```bash
# Make script executable (Windows)
cd scripts

# Option 1: PowerShell
powershell -ExecutionPolicy Bypass -File setup.ps1

# Option 2: Bash (Git Bash on Windows)
bash setup.sh
```

This script will:
- ✓ Check all prerequisites
- ✓ Create .gitignore and .env files
- ✓ Install Node dependencies
- ✓ Build Docker image
- ✓ Start all services
- ✓ Wait for services to be ready
- ✓ Display access URLs

---

## 🔍 Testing & Verification

### Health Checks
```bash
# Application health
curl http://localhost:3000/health

# Application ready
curl http://localhost:3000/ready

# Application status
curl http://localhost:3000/api/status

# Deployment info
curl http://localhost:3000/api/deployment-info

# Metrics (Prometheus)
curl http://localhost:3000/metrics
```

### Run Tests
```bash
# Unit tests
cd app
npm test

# Integration tests
npm run test:integration

# Check code quality
npm run lint
```

### Health Check Script
```bash
bash scripts/health-check.sh
```

---

## 📊 Monitoring & Logs

### View Container Logs
```bash
# All services
docker-compose -f docker/docker-compose.yml logs -f

# Specific service
docker logs -f devops-cicd-app
docker logs -f jenkins

# Watch logs with tail
docker logs --tail 100 -f devops-cicd-app
```

### Prometheus Metrics
- URL: http://localhost:9090
- Query Examples:
  ```
  http_requests_total{job="application"}
  http_request_duration_ms{method="GET"}
  ```

### Grafana Dashboards
- URL: http://localhost:3001
- Login: admin / admin
- Add data source: http://prometheus:9090

---

## 🚀 Deployment Workflow

### 1. Local Development
```bash
# Start environment
docker-compose -f docker/docker-compose.yml up -d

# Make code changes
edit app/src/index.js

# Test locally
curl http://localhost:3000/api/test

# Commit changes
git add .
git commit -m "feat(app): add new endpoint"
```

### 2. Pipeline Execution
```bash
# Push to repository
git push origin main

# Pipeline automatically:
# 1. Pulls code
# 2. Builds application
# 3. Runs tests
# 4. Creates Docker image
# 5. Pushes to registry
# 6. Deploys to staging
# 7. Runs smoke tests
# 8. Waits for approval
# 9. Deploys to production
```

### 3. Production Deployment
```bash
# Manual approval required in Jenkins
# Once approved:
kubectl rollout status deployment/devops-app -n production

# Monitor deployment
kubectl get pods -n production
kubectl logs -f deployment/devops-app -n production
```

---

## 🔄 Troubleshooting

### Application Won't Start
```bash
# Check Docker daemon
docker ps

# View application logs
docker logs devops-cicd-app

# Check port conflicts
netstat -an | findstr :3000

# Rebuild image
docker build --no-cache -f docker/Dockerfile -t devops-cicd-app:latest .
```

### Jenkins Issues
```bash
# Check Jenkins logs
docker logs jenkins

# Reconnect Docker socket
docker run -d --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:latest
```

### Database Connection Issues
```bash
# Check PostgreSQL
docker exec devops-postgres psql -U devops -d devops_db -c "SELECT 1"

# View database logs
docker logs devops-postgres

# Reset database
docker-compose -f docker/docker-compose.yml down -v
docker-compose -f docker/docker-compose.yml up -d
```

### Kubernetes Issues
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# Describe problematic pod
kubectl describe pod <pod-name> -n devops-prod

# Check events
kubectl get events -n devops-prod --sort-by='.lastTimestamp'

# Delete and recreate deployment
kubectl delete deployment devops-app -n devops-prod
kubectl apply -f kubernetes/deployment.yaml -n devops-prod
```

---

## 🔐 Security Considerations

### Before Production Deployment

1. **Change Default Passwords**
   ```bash
   # Grafana admin password
   # PgAdmin password
   # PostgreSQL password
   ```

2. **Configure Secrets**
   ```bash
   kubectl create secret generic app-secrets \
     --from-literal=db-password=<secure-pwd> \
     -n devops-prod
   ```

3. **Enable HTTPS**
   - Configure certificate manager
   - Update ingress with TLS

4. **Setup RBAC**
   - Already configured in `kubernetes/rbac.yaml`
   - Restrict service account permissions

5. **Image Security**
   - Use private registry
   - Sign images
   - Scan for vulnerabilities

---

## 📚 Important Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `docker/Dockerfile` | Application container definition |
| `docker/docker-compose.yml` | Local development stack |
| `jenkins/Jenkinsfile` | CI/CD pipeline definition |
| `kubernetes/deployment.yaml` | Kubernetes deployment |
| `app/src/index.js` | Node.js application |
| `scripts/setup.sh` | Automated setup |
| `scripts/deploy.sh` | Kubernetes deployment script |
| `scripts/health-check.sh` | Service health verification |

---

## 💡 Quick Commands Reference

```bash
# Setup
docker-compose -f docker/docker-compose.yml up -d

# Testing
curl http://localhost:3000/health
npm test

# Building
docker build -f docker/Dockerfile -t devops-cicd-app:latest .

# Pipeline
# Push to Git → Jenkins auto-builds → Deploy

# Monitoring
docker ps
docker logs -f devops-cicd-app
kubectl logs -f deployment/devops-app -n devops-prod

# Cleanup
docker-compose down
docker system prune -a
```

---

## 📞 Support & Resources

- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Docker Documentation**: https://docs.docker.com/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Project Issues**: Create issue in repository

---

**Version**: 1.0.0  
**Last Updated**: April 12, 2026  
**Status**: Production Ready
