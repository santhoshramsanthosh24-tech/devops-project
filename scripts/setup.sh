#!/bin/bash

################################################################################
# DevOps CI/CD Project Setup Script
# Initializes the complete DevOps environment
################################################################################

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║   DevOps CI/CD Project Setup                          ║"
echo "╚════════════════════════════════════════════════════════╝"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==============================================================================
# Check Prerequisites
# ==============================================================================
echo -e "\n${YELLOW}1. Checking prerequisites...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 is not installed${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

echo "Checking required commands..."
check_command docker || (echo "Please install Docker"; exit 1)
check_command docker-compose || (echo "Please install Docker Compose"; exit 1)
check_command git || (echo "Please install Git"; exit 1)
check_command node || (echo "Please install Node.js"; exit 1)

# ==============================================================================
# Initialize Git Repository
# ==============================================================================
echo -e "\n${YELLOW}2. Initializing Git repository...${NC}"

if [ ! -d .git ]; then
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
else
    echo -e "${GREEN}✓ Git repository already exists${NC}"
fi

# ==============================================================================
# Create .gitignore
# ==============================================================================
echo -e "\n${YELLOW}3. Creating .gitignore...${NC}"

cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json
dist/
build/

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Docker
.dockerignore
docker-compose.override.yml

# Jenkins
.jenkins/

# Kubernetes
kubeconfig
*.kubeconfig

# Build artifacts
dist/
build/
.next/
.nuxt/

# Coverage
coverage/
.nyc_output/

# Temporary files
tmp/
temp/
*.tmp
EOF

echo -e "${GREEN}✓ .gitignore created${NC}"

# ==============================================================================
# Create environment files
# ==============================================================================
echo -e "\n${YELLOW}4. Creating environment configuration files...${NC}"

cat > .env.example << 'EOF'
# Node Environment
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# Docker
DOCKER_REGISTRY=docker.io
DOCKER_USERNAME=your_username
DOCKER_PASSWORD=your_password

# Jenkins
JENKINS_URL=http://localhost:8080
JENKINS_USER=admin

# Kubernetes
KUBE_CONTEXT=docker-desktop
KUBE_NAMESPACE=default

# Deployment
DEPLOYMENT_ENV=dev
DEPLOY_REGION=us-east-1
EOF

echo -e "${GREEN}✓ Environment files created${NC}"

# ==============================================================================
# Install Node Dependencies
# ==============================================================================
echo -e "\n${YELLOW}5. Installing Node.js dependencies...${NC}"

cd app
if [ ! -d node_modules ]; then
    npm install
    echo -e "${GREEN}✓ Node dependencies installed${NC}"
else
    echo -e "${GREEN}✓ Node dependencies already installed${NC}"
fi
cd ..

# ==============================================================================
# Create logs directory
# ==============================================================================
echo -e "\n${YELLOW}6. Creating logs directory...${NC}"

mkdir -p logs
mkdir -p docker/logs
mkdir -p jenkins/logs

echo -e "${GREEN}✓ Logs directory created${NC}"

# ==============================================================================
# Build Docker Image
# ==============================================================================
echo -e "\n${YELLOW}7. Building Docker image...${NC}"

docker build \
    -f docker/Dockerfile \
    -t devops-cicd-app:latest \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
    .

echo -e "${GREEN}✓ Docker image built successfully${NC}"

# ==============================================================================
# Start Services with Docker Compose
# ==============================================================================
echo -e "\n${YELLOW}8. Starting services with Docker Compose...${NC}"

docker-compose -f docker/docker-compose.yml up -d

echo -e "${GREEN}✓ Services started${NC}"

# ==============================================================================
# Wait for services to be ready
# ==============================================================================
echo -e "\n${YELLOW}9. Waiting for services to be ready...${NC}"

echo "Waiting for application..."
for i in {1..30}; do
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Application is ready${NC}"
        break
    fi
    echo "  Attempt $i/30..."
    sleep 2
done

echo "Waiting for Jenkins..."
for i in {1..30}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Jenkins is ready${NC}"
        break
    fi
    echo "  Attempt $i/30..."
    sleep 2
done

# ==============================================================================
# Display Summary
# ==============================================================================
echo -e "\n╔════════════════════════════════════════════════════════╗"
echo -e "║   ${GREEN}Setup Complete!${NC}${'-'$(((53-14)/2))}║"
echo -e "╚════════════════════════════════════════════════════════╝"

echo -e "\n${GREEN}Available Services:${NC}"
echo "  • Application:    http://localhost:3000"
echo "  • Jenkins:        http://localhost:8080"
echo "  • Prometheus:     http://localhost:9090"
echo "  • Grafana:        http://localhost:3001 (admin/admin)"
echo "  • PgAdmin:        http://localhost:5050"
echo "  • Docker Registry: http://localhost:5000"

echo -e "\n${GREEN}Default Credentials:${NC}"
echo "  • Grafana Admin:  admin / admin"
echo "  • PgAdmin:        admin@devops.com / admin"
echo "  • PostgreSQL:     devops / devops_password_123"

echo -e "\n${GREEN}Next Steps:${NC}"
echo "  1. Access Jenkins at http://localhost:8080"
echo "  2. Get Jenkins admin password:"
echo "     docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo "  3. Create a new Pipeline job"
echo "  4. Connect to your Git repository"
echo "  5. Start pushing code to trigger the pipeline"

echo -e "\n${GREEN}Useful Commands:${NC}"
echo "  • View logs:     docker-compose -f docker/docker-compose.yml logs -f"
echo "  • Stop services: docker-compose -f docker/docker-compose.yml down"
echo "  • Restart:       docker-compose -f docker/docker-compose.yml restart"
echo "  • Health check:  curl http://localhost:3000/health"

echo -e "\n"
