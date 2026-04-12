# Quick Start Checklist ✓

## Pre-Launch Checklist

### System Requirements
- [ ] Docker Desktop installed
- [ ] Git installed  
- [ ] Node.js 16+ installed
- [ ] 4GB+ RAM available
- [ ] Ports 3000, 8080, 9090 not in use

### Initial Setup (5 minutes)

#### Option A: Automated Setup
```bash
# Navigate to project
cd e:\data engennering\Devops_project

# Run setup script (Git Bash or WSL)
bash scripts/setup.sh

# Follow prompts to complete setup
```

#### Option B: Manual Setup
```bash
# 1. Navigate to project
cd e:\data engennering\Devops_project

# 2. Build Docker image
docker build -f docker/Dockerfile -t devops-cicd-app:latest .

# 3. Start all services
docker-compose -f docker/docker-compose.yml up -d

# 4. Wait 30 seconds for services to start
# 5. Verify health
curl http://localhost:3000/health
```

### Post-Startup Tasks

#### 1. Access Jenkins
```bash
# Get admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Open http://localhost:8080 in browser
# Enter password, install plugins, create admin user
```

#### 2. Create Jenkins Pipeline Job
- [ ] Create new item → Pipeline
- [ ] Name: `DevOps-CI-CD-Pipeline`
- [ ] Set Definition: Pipeline script from SCM
- [ ] Repository: Your Git repository URL
- [ ] Branch: `*/main`
- [ ] Script Path: `jenkins/Jenkinsfile`
- [ ] Save and test

#### 3. Test Services
```bash
# Health checks
curl http://localhost:3000/health
curl http://localhost:3000/ready
curl http://localhost:3000/api/status

# Access services
# App:        http://localhost:3000
# Jenkins:    http://localhost:8080
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3001 (admin/admin)
# PgAdmin:    http://localhost:5050
```

#### 4. Run Tests
```bash
cd app
npm test
npm run test:integration
```

---

## Verification (Run These Commands)

### ✓ Verify Docker Containers
```bash
docker ps | grep -E "devops|jenkins|prometheus|grafana"
# Should show 6+ running containers
```

### ✓ Verify Network Connectivity
```bash
# Test application endpoints
curl -s http://localhost:3000/health | jq .
curl -s http://localhost:3000/api/version | jq .

# Test infrastructure
curl -s http://localhost:8080 | head -c 50
curl -s http://localhost:9090 | head -c 50
curl -s http://localhost:3001 | head -c 50
```

### ✓ Run Health Check Script
```bash
bash scripts/health-check.sh
# All checks should pass
```

### ✓ View Logs
```bash
docker-compose -f docker/docker-compose.yml logs --tail=50
```

---

## Success Indicators

### All Green ✓ if:
- [ ] Docker containers are running
- [ ] http://localhost:3000/health returns HTTP 200
- [ ] http://localhost:8080 loads Jenkins UI
- [ ] http://localhost:9090 shows Prometheus
- [ ] http://localhost:3001 shows Grafana
- [ ] All databases are connected
- [ ] Tests pass locally
- [ ] No error logs in console
- [ ] `bash scripts/health-check.sh` passes

---

## First Deployment

### Step 1: Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git init
git add .
git commit -m "Initial DevOps project setup"
```

### Step 2: Push to Repository
```bash
git remote add origin https://github.com/YOUR_USERNAME/devops-project
git push -u origin main
```

### Step 3: Trigger Pipeline
```bash
# In Jenkins, click "Build Now"
# Watch the pipeline execute all 15 stages
# Takes approximately 5-10 minutes
```

### Step 4: Monitor Deployment
```bash
# Watch logs
docker logs -f devops-cicd-app

# Check metrics
curl http://localhost:3000/metrics

# View pipeline status in Jenkins
# http://localhost:8080/job/DevOps-CI-CD-Pipeline/
```

---

## Common Issues & Quick Fixes

### Issue: Ports Already in Use
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Issue: Docker Service Won't Start
```bash
# Restart Docker
# On Windows: Restart Docker Desktop
# On Linux: sudo systemctl restart docker

# Or rebuild containers
docker-compose down -v
docker-compose up -d
```

### Issue: Jenkins Won't Connect to Docker
```bash
# Ensure Docker socket is mounted
docker run -d --name jenkins \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 8080:8080 \
  jenkins/jenkins:latest
```

### Issue: Out of Memory
```bash
# Increase Docker memory limit
# Windows: Docker Desktop → Settings → Resources
# Set Memory to 8GB or more
```

---

## Next Steps

1. **Read Documentation**
   - [ ] Read `README.md` - Project overview
   - [ ] Read `HOW_TO_RUN.md` - Detailed setup instructions
   - [ ] Read `PROJECT_STRUCTURE.md` - File structure explanation

2. **Explore Features**
   - [ ] Access Grafana dashboards
   - [ ] View Prometheus metrics
   - [ ] Check Jenkins logs
   - [ ] Inspect Kubernetes manifests

3. **Configure for Production**
   - [ ] Change default passwords
   - [ ] Set up private Docker registry credentials
   - [ ] Configure GitHub webhooks for Jenkins
   - [ ] Set up Kubernetes cluster access
   - [ ] Configure DNS for your domain

4. **Customize Application**
   - [ ] Update `app/src/index.js` with your logic
   - [ ] Modify Dockerfile for your needs
   - [ ] Update Jenkinsfile pipeline stages
   - [ ] Configure Kubernetes deployments

5. **Deploy to Production**
   - [ ] Create Kubernetes cluster
   - [ ] Push Docker image to registry
   - [ ] Apply Kubernetes manifests
   - [ ] Configure ingress/DNS
   - [ ] Set up monitoring & alerts

---

## Support Resources

### Official Documentation
- [Jenkins Docs](https://www.jenkins.io/doc/)
- [Docker Docs](https://docs.docker.com/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

### Environment Details
- **Application**: Node.js 18 + Express
- **CI/CD**: Jenkins with declarative pipeline
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes 1.25+
- **Database**: PostgreSQL 15
- **Monitoring**: Prometheus + Grafana

### Key Technologies
- Express.js - Web framework
- Prometheus - Metrics collection
- Grafana - Visualization
- Kubernetes - Container orchestration
- Jenkins - CI/CD automation

---

## Troubleshooting Commands

```bash
# Get detailed service status
docker-compose ps -a

# Rebuild specific service
docker-compose build app

# Full system cleanup and restart
docker-compose down -v
docker-compose up -d

# Check disk space (Docker might need cleanup)
docker system df
docker system prune -a

# Test specific endpoint
curl -v http://localhost:3000/health

# Check container resource usage
docker stats

# View Docker daemon logs
docker logs jenkins

# Reset everything (destructive)
docker-compose down -v
docker system prune -a --volumes
```

---

## Performance Tips

1. **Local Development**: Use `docker-compose up -d` instead of individual containers
2. **On WSL2**: Enable WSL2 integration in Docker settings
3. **Memory**: Allocate 8GB or more to Docker
4. **CPU**: Use at least 4 CPU cores
5. **Disk**: Ensure 20GB+ free space for images and containers

---

## Security Reminders

⚠️ **Before Production:**
- [ ] Change all default passwords
- [ ] Setup HTTPS/TLS certificates
- [ ] Create private Docker registry
- [ ] Configure Kubernetes RBAC properly
- [ ] Use sealed secrets for sensitive data
- [ ] Setup network policies
- [ ] Enable Pod Security Policies
- [ ] Scan images for vulnerabilities
- [ ] Configure firewall rules

---

## Enterprise Deployment Checklist

- [ ] Cluster setup and configuration
- [ ] Load balancer configuration
- [ ] Database backup & recovery
- [ ] Monitoring & alerting
- [ ] Log aggregation
- [ ] Disaster recovery plan
- [ ] Security scanning & compliance
- [ ] SSL/TLS certificates
- [ ] DNS configuration
- [ ] CI/CD webhook setup

---

**Status**: ✓ Ready to Deploy  
**Version**: 1.0.0  
**Last Updated**: April 12, 2026  
**Estimated Setup Time**: 5-15 minutes

## 🎉 You're Ready!

Start with:
```bash
cd e:\data engennering\Devops_project
docker-compose -f docker/docker-compose.yml up -d
curl http://localhost:3000/health
```

Then open http://localhost:3000 in your browser! 🚀
