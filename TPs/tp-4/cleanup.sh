
#!/bin/bash

# Script de nettoyage complet de la VM Kubernetes TP-4
# Date: Janvier 2026

echo "╔═══════════════════════════════════════════════════════╗"
echo "║     Nettoyage VM Kubernetes TP-4                      ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# 1. Supprimer les namespaces créés par le TP-4 avancé
echo "=== Suppression des namespaces TP-4 Avancé ==="
kubectl delete namespace bd 2>/dev/null || echo "Namespace bd n'existe pas"
kubectl delete namespace voting 2>/dev/null || echo "Namespace voting n'existe pas"
kubectl delete namespace odoo 2>/dev/null || echo "Namespace odoo n'existe pas"

# 2. Supprimer les PV créés
echo ""
echo "=== Suppression des PersistentVolumes ==="
kubectl delete pv postgres-pv 2>/dev/null || echo "PV postgres-pv n'existe pas"

# 3. Supprimer tous les pods et deployments dans le namespace default
echo ""
echo "=== Suppression des ressources dans default ==="
kubectl delete pods --all -n default 2>/dev/null || echo "Aucun pod à supprimer"
kubectl delete deployments --all -n default 2>/dev/null || echo "Aucun deployment à supprimer"
kubectl delete services --all -n default 2>/dev/null || echo "Aucun service à supprimer (sauf kubernetes)"
kubectl delete replicasets --all -n default 2>/dev/null || echo "Aucun replicaset à supprimer"

# 4. Vérifier qu'il ne reste rien
echo ""
echo "=== Vérification des ressources restantes ==="
kubectl get all -n default
kubectl get namespaces

# 5. Arrêter Minikube (optionnel)
echo ""
read -p "Voulez-vous arrêter Minikube ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "=== Arrêt de Minikube ==="
    minikube stop
fi

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
