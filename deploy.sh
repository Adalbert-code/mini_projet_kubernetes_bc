#!/bin/bash

# PayMyBuddy - Automated Kubernetes Deployment Script
# Author: Adalbert NANDA TONLIO

set -e  # Exit on error

echo "=========================================="
echo "  PayMyBuddy - Kubernetes Deployment"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ kubectl found${NC}"
}

# Function to check cluster connectivity
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Connected to Kubernetes cluster${NC}"
}

# Function to deploy resources
deploy() {
    echo ""
    echo -e "${YELLOW}🚀 Starting deployment...${NC}"
    echo ""
    
    # Step 1: Create PersistentVolume and PersistentVolumeClaim
    echo -e "${YELLOW}📦 Creating PersistentVolume and PVC...${NC}"
    kubectl apply -f paymybuddy-pv.yaml
    kubectl apply -f paymybuddy-pvc.yaml
    sleep 2
    
    # Step 2: Deploy MySQL
    echo -e "${YELLOW}🗄️  Deploying MySQL database...${NC}"
    kubectl apply -f mysql-deployment.yaml
    kubectl apply -f mysql-service.yaml
    
    # Wait for MySQL to be ready
    echo -e "${YELLOW}⏳ Waiting for MySQL to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s
    echo -e "${GREEN}✅ MySQL is ready${NC}"
    
    # Step 3: Deploy PayMyBuddy
    echo -e "${YELLOW}🏦 Deploying PayMyBuddy application...${NC}"
    kubectl apply -f paymybuddy-deployment.yaml
    kubectl apply -f paymybuddy-service.yaml
    
    # Wait for PayMyBuddy to be ready
    echo -e "${YELLOW}⏳ Waiting for PayMyBuddy to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=paymybuddy --timeout=180s
    echo -e "${GREEN}✅ PayMyBuddy is ready${NC}"
}

# Function to display status
show_status() {
    echo ""
    echo "=========================================="
    echo "  Deployment Status"
    echo "=========================================="
    echo ""
    
    echo -e "${YELLOW}📋 Pods:${NC}"
    kubectl get pods
    echo ""
    
    echo -e "${YELLOW}🌐 Services:${NC}"
    kubectl get svc
    echo ""
    
    echo -e "${YELLOW}💾 Persistent Volumes:${NC}"
    kubectl get pv,pvc
    echo ""
}

# Function to get access URL
get_access_url() {
    echo "=========================================="
    echo "  Access Information"
    echo "=========================================="
    echo ""
    
    # Check if running on Minikube
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        echo -e "${GREEN}🎯 Minikube detected${NC}"
        echo ""
        echo "Access PayMyBuddy at:"
        minikube service paymybuddy --url
        echo ""
        echo "Or open directly in browser:"
        echo "  minikube service paymybuddy"
    else
        echo -e "${YELLOW}📝 Get your node IP:${NC}"
        echo "  kubectl get nodes -o wide"
        echo ""
        echo -e "${YELLOW}🌐 Access PayMyBuddy at:${NC}"
        echo "  http://<NODE_IP>:30080"
        echo ""
        echo -e "${YELLOW}🔍 For local clusters (Docker Desktop, Kind, K3s):${NC}"
        echo "  http://localhost:30080"
    fi
    
    echo ""
}

# Function to show logs
show_logs() {
    echo "=========================================="
    echo "  Application Logs"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}📄 PayMyBuddy logs (last 20 lines):${NC}"
    kubectl logs -l app=paymybuddy --tail=20
    echo ""
}

# Main execution
main() {
    check_kubectl
    check_cluster
    deploy
    show_status
    get_access_url
    show_logs
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo "  ✅ Deployment completed successfully!"
    echo "==========================================${NC}"
    echo ""
}

# Run main function
main
