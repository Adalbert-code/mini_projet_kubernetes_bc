#!/bin/bash

# PayMyBuddy - Kubernetes Cleanup Script
# Author: Adalbert NANDA TONLIO

---------------------------------------------------------------------------------------------
# set -e

# echo "=========================================="
# echo "  PayMyBuddy - Cleanup"
# echo "=========================================="
# echo ""

# # Colors
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# RED='\033[0;31m'
# NC='\033[0m'

# echo -e "${YELLOW}⚠️  This will delete all PayMyBuddy resources from Kubernetes${NC}"
# read -p "Are you sure? (yes/no): " confirm

# if [ "$confirm" != "yes" ]; then
#     echo "Cleanup cancelled."
#     exit 0
# fi

# echo ""
# echo -e "${YELLOW}🧹 Deleting resources...${NC}"
# echo ""

# # Delete in reverse order
# echo "Deleting PayMyBuddy service..."
# kubectl delete -f paymybuddy-service.yaml --ignore-not-found=true

# echo "Deleting PayMyBuddy deployment..."
# kubectl delete -f paymybuddy-deployment.yaml --ignore-not-found=true

# echo "Deleting MySQL service..."
# kubectl delete -f mysql-service.yaml --ignore-not-found=true

# echo "Deleting MySQL deployment..."
# kubectl delete -f mysql-deployment.yaml --ignore-not-found=true

# echo "Deleting PersistentVolumeClaim..."
# kubectl delete -f paymybuddy-pvc.yaml --ignore-not-found=true

# echo "Deleting PersistentVolume..."
# kubectl delete -f paymybuddy-pv.yaml --ignore-not-found=true

# echo ""
# echo -e "${GREEN}✅ Cleanup completed!${NC}"
# echo ""
# echo "Remaining resources:"
# kubectl get all,pv,pvc
---------------------------------------------------------------------------------------
#!/bin/bash

# Mini-Projet Kubernetes C - Script de nettoyage
# Auteur: Adalbert NANDA

echo "=========================================="
echo "  Nettoyage Mini-Projet WordPress"
echo "=========================================="

# 1. Supprimer le namespace (supprime tout dedans)
echo ""
echo "Suppression du namespace wordpress..."
kubectl delete namespace wordpress 2>/dev/null || echo "Namespace wordpress n'existe pas"

# 2. Supprimer les PV
echo ""
echo "Suppression des PersistentVolumes..."
kubectl delete pv mysql-pv 2>/dev/null || echo "PV mysql-pv n'existe pas"
kubectl delete pv wordpress-pv 2>/dev/null || echo "PV wordpress-pv n'existe pas"

# 3. Optionnel: supprimer les donnees
echo ""
read -p "Voulez-vous supprimer les donnees dans /data ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Suppression des donnees..."
    sudo rm -rf /data/mysql
    sudo rm -rf /data/wordpress
    echo "Donnees supprimees"
fi

# 4. Verification
echo ""
echo "Verification:"
kubectl get all -n wordpress 2>/dev/null || echo "Namespace wordpress supprime"
kubectl get pv | grep -E "mysql|wordpress" || echo "PV supprimes"

echo ""
echo "Nettoyage termine!"
