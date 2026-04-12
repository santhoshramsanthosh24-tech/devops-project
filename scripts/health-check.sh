#!/bin/bash

################################################################################
# Health Check Script for DevOps CI/CD Application
# Verifies that all services are running properly
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Health Check - DevOps CI/CD Services              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

FAILED=0
PASSED=0

# Function to check service health
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -ne "${YELLOW}Checking $name...${NC}"
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_code" ]; then
        echo -e " ${GREEN}✓ OK${NC} (HTTP $status_code)"
        ((PASSED++))
    else
        echo -e " ${RED}✗ FAILED${NC} (HTTP $status_code, expected $expected_code)"
        ((FAILED++))
    fi
}

# Function to check docker service
check_docker_service() {
    local container=$1
    local port=$2
    local name=$3
    
    echo -ne "${YELLOW}Checking $name (Docker)...${NC}"
    
    if docker ps | grep -q $container; then
        echo -e " ${GREEN}✓ Running${NC}"
        ((PASSED++))
    else
        echo -e " ${RED}✗ Not Running${NC}"
        ((FAILED++))
    fi
}

echo ""
echo -e "${BLUE}Application Services:${NC}"
check_service "Application Root" "http://localhost:3000/" 200
check_service "Application Health" "http://localhost:3000/health" 200
check_service "Application Ready" "http://localhost:3000/ready" 200
check_service "Application Metrics" "http://localhost:3000/metrics" 200
check_service "Application API Version" "http://localhost:3000/api/version" 200

echo ""
echo -e "${BLUE}Infrastructure Services:${NC}"
check_service "Jenkins" "http://localhost:8080/" 200
check_service "Prometheus" "http://localhost:9090/" 200
check_service "Grafana" "http://localhost:3001/" 200
check_service "PgAdmin" "http://localhost:5050/" 200
check_service "Docker Registry" "http://localhost:5000/v2/" 200

echo ""
echo -e "${BLUE}Docker Container Status:${NC}"
check_docker_service "devops-cicd-app" 3000 "Application"
check_docker_service "jenkins" 8080 "Jenkins"
check_docker_service "prometheus" 9090 "Prometheus"
check_docker_service "grafana" 3001 "Grafana"
check_docker_service "postgres" 5432 "PostgreSQL"

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Health Check Summary                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ All services are healthy!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some services are not healthy${NC}"
    exit 1
fi
