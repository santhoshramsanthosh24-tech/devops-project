#!/bin/bash

################################################################################
# Rollback Script for DevOps CI/CD Application
# Reverts to previous deployment version
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rollback Script - DevOps CI/CD Application         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

# Configuration
NAMESPACE=${1:-default}
DEPLOYMENT=${2:-devops-app}

echo -e "\n${YELLOW}Rollback Configuration:${NC}"
echo "  Namespace:  $NAMESPACE"
echo "  Deployment: $DEPLOYMENT"

# ==============================================================================
# Check Prerequisites
# ==============================================================================
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl is available${NC}"

# ==============================================================================
# Get Rollout History
# ==============================================================================
echo -e "\n${YELLOW}Deployment Rollout History:${NC}"

kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE || {
    echo -e "${RED}✗ Failed to get rollout history${NC}"
    exit 1
}

# ==============================================================================
# Confirm Rollback
# ==============================================================================
echo -e "\n${RED}⚠️  WARNING: You are about to rollback the deployment!${NC}"
read -p "Type 'yes' to confirm rollback to previous version: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Rollback cancelled${NC}"
    exit 0
fi

# ==============================================================================
# Perform Rollback
# ==============================================================================
echo -e "\n${YELLOW}Performing rollback...${NC}"

kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE --record

echo -e "${GREEN}✓ Rollback initiated${NC}"

# ==============================================================================
# Wait for Rollout
# ==============================================================================
echo -e "\n${YELLOW}Waiting for rollback to complete...${NC}"

kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m

echo -e "${GREEN}✓ Rollback completed successfully${NC}"

# ==============================================================================
# Display Summary
# ==============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ${GREEN}Rollback Complete!${BLUE}                               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Rollback Summary:${NC}"
echo "  Deployment: $DEPLOYMENT"
echo "  Namespace:  $NAMESPACE"
echo "  Status:     Rolled back to previous version"
echo "  Pods:       $(kubectl get pods -n $NAMESPACE -l app=devops-cicd-app | grep Running | wc -l) running"

echo -e "\n${GREEN}Useful Commands:${NC}"
echo "  • View logs:      kubectl logs -f deployment/$DEPLOYMENT -n $NAMESPACE"
echo "  • Check status:   kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE"
echo "  • Rollout history: kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE"

echo -e "\n"
