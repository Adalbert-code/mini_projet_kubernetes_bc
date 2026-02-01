
#!/bin/bash

# Script de nettoyage complet de la VM Kubernetes TP-2
# Date: Janvier 2026

echo "╔═══════════════════════════════════════════════════════╗"
echo "║     Nettoyage VM Kubernetes TP-2                      ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# 1. Supprimer tous les pods et deployments dans le namespace default
echo "=== Suppression des ressources Kubernetes ==="
kubectl delete pods --all -n default 2>/dev/null || echo "Aucun pod à supprimer"
kubectl delete deployments --all -n default 2>/dev/null || echo "Aucun deployment à supprimer"
kubectl delete services --all -n default 2>/dev/null || echo "Aucun service à supprimer (sauf kubernetes)"
kubectl delete replicasets --all -n default 2>/dev/null || echo "Aucun replicaset à supprimer"

# 2. Vérifier qu'il ne reste rien
echo ""
echo "=== Vérification des ressources restantes ==="
kubectl get all -n default

# 3. Arrêter Minikube
echo ""
echo "=== Arrêt de Minikube ==="
minikube stop

echo ""
echo "✅ Nettoyage terminé !"
echo ""
echo "État actuel :"
echo "- ✓ Tous les pods supprimés"
echo "- ✓ Tous les deployments supprimés"
echo "- ✓ Tous les services supprimés (sauf kubernetes)"
echo "- ✓ Minikube arrêté"
echo ""
echo "Pour redémarrer Minikube :"
echo "  sudo minikube start --driver=none --container-runtime=containerd --force"
echo ""
echo "Pour supprimer complètement Minikube (si besoin) :"
echo "  sudo minikube delete --all --purge"
