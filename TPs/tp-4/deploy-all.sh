#!/bin/bash

# TP-4 Avancé - Script de déploiement complet
# Auteur: Adalbert NANDA

set -e

echo "=========================================="
echo "   TP-4 Avancé - Déploiement Complet"
echo "=========================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 1. Activer les addons minikube
echo ""
echo "1. Configuration des addons Minikube..."
minikube addons enable ingress || print_warning "Ingress déjà activé"
minikube addons enable metallb || print_warning "MetalLB déjà activé"
print_status "Addons configurés"

# Attendre que l'Ingress Controller soit prêt
echo "   Attente de l'Ingress Controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s || print_warning "Timeout atteint, continuons..."
print_status "Ingress Controller prêt"

# 2. Déployer PostgreSQL + PgAdmin
echo ""
echo "2. Déploiement PostgreSQL + PgAdmin (namespace: bd)..."
kubectl apply -f postgresql/namespace.yaml
kubectl apply -f postgresql/postgres-secret.yaml
kubectl apply -f postgresql/postgres-pv.yaml
kubectl apply -f postgresql/postgres-deployment.yaml
kubectl apply -f postgresql/pgadmin-deployment.yaml
kubectl apply -f ingress/pgadmin-ingress.yaml
print_status "PostgreSQL + PgAdmin déployés"

# 3. Déployer Voting App
echo ""
echo "3. Déploiement Example-Voting-App (namespace: voting)..."
kubectl apply -f voting-app/namespace.yaml
kubectl apply -f voting-app/redis-deployment.yaml
kubectl apply -f voting-app/db-deployment.yaml
kubectl apply -f voting-app/vote-deployment.yaml
kubectl apply -f voting-app/result-deployment.yaml
kubectl apply -f voting-app/worker-deployment.yaml
kubectl apply -f ingress/voting-app-ingress.yaml
print_status "Voting App déployée"

# 4. Déployer Odoo
echo ""
echo "4. Déploiement Odoo ERP (namespace: odoo)..."
kubectl apply -f odoo/namespace.yaml
kubectl apply -f odoo/odoo-secret.yaml
kubectl apply -f odoo/odoo-postgres-deployment.yaml
kubectl apply -f odoo/odoo-deployment.yaml
kubectl apply -f ingress/odoo-ingress.yaml
print_status "Odoo ERP déployé"

# 5. Afficher le récapitulatif
echo ""
echo "=========================================="
echo "   Récapitulatif du déploiement"
echo "=========================================="

echo ""
echo "Namespaces créés:"
kubectl get namespaces | grep -E "bd|voting|odoo"

echo ""
echo "Pods en cours d'exécution:"
kubectl get pods --all-namespaces | grep -E "bd|voting|odoo"

echo ""
echo "Services créés (tous en ClusterIP):"
kubectl get svc --all-namespaces | grep -E "bd|voting|odoo"

echo ""
echo "Ingress configurés:"
kubectl get ingress --all-namespaces

echo ""
echo "=========================================="
echo "   Configuration DNS requise"
echo "=========================================="
MINIKUBE_IP=$(minikube ip)
echo ""
echo "Ajoutez cette ligne à /etc/hosts :"
echo ""
echo "  $MINIKUBE_IP pgadmin.local vote.local result.local odoo.local"
echo ""
echo "Commande: echo \"$MINIKUBE_IP pgadmin.local vote.local result.local odoo.local\" | sudo tee -a /etc/hosts"

echo ""
echo "=========================================="
echo "   URLs d'accès"
echo "=========================================="
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "80")
echo ""
echo "  PgAdmin:  http://pgadmin.local (admin@local.dev / admin123)"
echo "  Vote:     http://vote.local"
echo "  Result:   http://result.local"
echo "  Odoo:     http://odoo.local"
echo ""
echo "Test avec curl:"
echo "  curl -H 'Host: vote.local' http://localhost:$INGRESS_PORT"
echo ""
print_status "Déploiement terminé avec succès!"
