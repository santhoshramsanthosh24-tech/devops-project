#!/bin/bash

################################################################################
# Deployment Script for DevOps CI/CD Application
# Handles deployment to different environments
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
NAMESPACE=${3:-default}

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   DevOps Deployment Script                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

# ==============================================================================
# Validate Arguments
# ==============================================================================
echo -e "\n${YELLOW}1. Validating deployment parameters...${NC}"

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo -e "${RED}✗ Invalid environment: $ENVIRONMENT${NC}"
    echo "  Valid options: dev, staging, production"
    exit 1
fi

echo -e "${GREEN}✓ Environment: $ENVIRONMENT${NC}"
echo -e "${GREEN}✓ Image Tag: $IMAGE_TAG${NC}"
echo -e "${GREEN}✓ Namespace: $NAMESPACE${NC}"

# ==============================================================================
# Confirm Deployment for Production
# ==============================================================================
if [ "$ENVIRONMENT" = "production" ]; then
    echo -e "\n${RED}⚠️  WARNING: You are about to deploy to PRODUCTION!${NC}"
    read -p "Type 'yes' to confirm: " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
fi

# ==============================================================================
# Check Prerequisites
# ==============================================================================
echo -e "\n${YELLOW}2. Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl is available${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ docker is available${NC}"

# ==============================================================================
# Build Docker Image
# ==============================================================================
echo -e "\n${YELLOW}3. Building Docker image...${NC}"

docker build \
    -f docker/Dockerfile \
    -t devops-cicd-app:${IMAGE_TAG} \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
    .

echo -e "${GREEN}✓ Docker image built: devops-cicd-app:${IMAGE_TAG}${NC}"

# ==============================================================================
# Tag and Push Image
# ==============================================================================
echo -e "\n${YELLOW}4. Tagging and pushing image...${NC}"

read -p "Enter Docker registry username: " DOCKER_USERNAME
read -sp "Enter Docker registry password: " DOCKER_PASSWORD
echo

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

REGISTRY="docker.io"
FULL_IMAGE="${REGISTRY}/${DOCKER_USERNAME}/devops-cicd-app:${IMAGE_TAG}"

docker tag devops-cicd-app:${IMAGE_TAG} $FULL_IMAGE
docker push $FULL_IMAGE

echo -e "${GREEN}✓ Image pushed: $FULL_IMAGE${NC}"

# ==============================================================================
# Create/Update Kubernetes Namespace
# ==============================================================================
echo -e "\n${YELLOW}5. Setting up Kubernetes namespace...${NC}"

if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    kubectl create namespace $NAMESPACE
    echo -e "${GREEN}✓ Namespace created: $NAMESPACE${NC}"
else
    echo -e "${GREEN}✓ Namespace exists: $NAMESPACE${NC}"
fi

# ==============================================================================
# Create Image Pull Secret (if using private registry)
# ==============================================================================
echo -e "\n${YELLOW}6. Setting up image pull secrets...${NC}"

SECRET_NAME="dockercfg"

if ! kubectl get secret $SECRET_NAME -n $NAMESPACE > /dev/null 2>&1; then
    kubectl create secret docker-registry $SECRET_NAME \
        --docker-server=docker.io \
        --docker-username=$DOCKER_USERNAME \
        --docker-password=$DOCKER_PASSWORD \
        --docker-email=devops@example.com \
        -n $NAMESPACE
    echo -e "${GREEN}✓ Image pull secret created${NC}"
else
    echo -e "${GREEN}✓ Image pull secret already exists${NC}"
fi

# ==============================================================================
# Apply Kubernetes Manifests
# ==============================================================================
echo -e "\n${YELLOW}7. Applying Kubernetes manifests...${NC}"

echo "Applying ConfigMap..."
kubectl apply -f kubernetes/configmap.yaml -n $NAMESPACE

echo "Applying RBAC..."
kubectl apply -f kubernetes/rbac.yaml -n $NAMESPACE

echo "Applying Deployment..."
kubectl set image deployment/devops-app \
    devops-app=$FULL_IMAGE \
    -n $NAMESPACE \
    --record \
    2>/dev/null || kubectl apply -f kubernetes/deployment.yaml -n $NAMESPACE

echo "Applying Service..."
kubectl apply -f kubernetes/service.yaml -n $NAMESPACE

echo "Applying Ingress..."
kubectl apply -f kubernetes/ingress.yaml -n $NAMESPACE

echo -e "${GREEN}✓ Kubernetes manifests applied${NC}"

# ==============================================================================
# Wait for Rollout
# ==============================================================================
echo -e "\n${YELLOW}8. Waiting for deployment to rollout...${NC}"

kubectl rollout status deployment/devops-app -n $NAMESPACE --timeout=5m

echo -e "${GREEN}✓ Deployment rolled out successfully${NC}"

# ==============================================================================
# Verify Deployment
# ==============================================================================
echo -e "\n${YELLOW}9. Verifying deployment...${NC}"

echo "Running smoke tests..."

# Get a pod name
POD=$(kubectl get pods -n $NAMESPACE -l app=devops-cicd-app -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo -e "${RED}✗ No running pods found${NC}"
    exit 1
fi

# Test endpoints
echo "Testing /health endpoint..."
kubectl exec $POD -n $NAMESPACE -- curl -s http://localhost:3000/health | head -c 50
echo ""

echo -e "${GREEN}✓ Smoke tests passed${NC}"

# ==============================================================================
# Display Deployment Summary
# ==============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ${GREEN}Deployment Complete!${BLUE}                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Deployment Summary:${NC}"
echo "  Environment: $ENVIRONMENT"
echo "  Namespace:   $NAMESPACE"
echo "  Image:       $FULL_IMAGE"
echo "  Replicas:    $(kubectl get deployment devops-app -n $NAMESPACE -o jsonpath='{.spec.replicas}')"

echo -e "\n${GREEN}Useful kubectl Commands:${NC}"
echo "  • Get pods:       kubectl get pods -n $NAMESPACE -l app=devops-cicd-app"
echo "  • View logs:      kubectl logs -f deployment/devops-app -n $NAMESPACE"
echo "  • Describe pod:   kubectl describe pod <pod-name> -n $NAMESPACE"
echo "  • Port forward:   kubectl port-forward svc/devops-app-service 3000:80 -n $NAMESPACE"
echo "  • Rollout status: kubectl rollout status deployment/devops-app -n $NAMESPACE"
echo "  • Rollback:       kubectl rollout undo deployment/devops-app -n $NAMESPACE"

echo -e "\n"
