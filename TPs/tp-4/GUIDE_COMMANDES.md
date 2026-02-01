# Guide des Commandes - TP-4 Avance

Reference complete des commandes Kubernetes pour le TP-4.

---

## Table des matieres

1. [Commandes de Base](#commandes-de-base)
2. [Gestion des Namespaces](#gestion-des-namespaces)
3. [Gestion des Pods](#gestion-des-pods)
4. [Gestion des Deployments](#gestion-des-deployments)
5. [Gestion des Services](#gestion-des-services)
6. [Gestion des Ingress](#gestion-des-ingress)
7. [Gestion des Secrets](#gestion-des-secrets)
8. [Gestion des PV/PVC](#gestion-des-pvpvc)
9. [Commandes Minikube](#commandes-minikube)
10. [Commandes de Debug](#commandes-de-debug)

---

## Commandes de Base

### Obtenir des informations sur le cluster

```bash
# Informations du cluster
kubectl cluster-info

# Version de Kubernetes
kubectl version

# Liste des noeuds
kubectl get nodes

# Details d'un noeud
kubectl describe node minikube

# Voir toutes les ressources
kubectl get all --all-namespaces
```

### Appliquer et supprimer des manifestes

```bash
# Appliquer un fichier YAML
kubectl apply -f fichier.yaml

# Appliquer tous les fichiers d'un repertoire
kubectl apply -f repertoire/

# Supprimer avec un fichier
kubectl delete -f fichier.yaml

# Supprimer toutes les ressources d'un repertoire
kubectl delete -f repertoire/
```

---

## Gestion des Namespaces

### Lister les namespaces

```bash
# Tous les namespaces
kubectl get namespaces
kubectl get ns

# Namespaces du TP-4
kubectl get ns | grep -E "bd|voting|odoo"
```

### Creer/Supprimer un namespace

```bash
# Creer un namespace
kubectl create namespace mon-namespace

# Creer depuis un fichier
kubectl apply -f namespace.yaml

# Supprimer un namespace (supprime TOUT dedans!)
kubectl delete namespace mon-namespace
```

### Changer de namespace par defaut

```bash
# Utiliser un namespace specifique pour les commandes
kubectl config set-context --current --namespace=voting

# Revenir au namespace default
kubectl config set-context --current --namespace=default

# Verifier le namespace actuel
kubectl config view --minify | grep namespace
```

---

## Gestion des Pods

### Lister les pods

```bash
# Pods du namespace default
kubectl get pods

# Pods d'un namespace specifique
kubectl get pods -n bd
kubectl get pods -n voting
kubectl get pods -n odoo

# Pods de tous les namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Pods avec plus de details
kubectl get pods -o wide

# Pods avec labels
kubectl get pods --show-labels
```

### Voir les details d'un pod

```bash
# Description complete
kubectl describe pod nom-du-pod -n namespace

# Exemples TP-4
kubectl describe pod -n bd -l app=postgres
kubectl describe pod -n voting -l app=vote
kubectl describe pod -n odoo -l app=odoo
```

### Logs des pods

```bash
# Logs d'un pod
kubectl logs nom-du-pod -n namespace

# Logs en temps reel (follow)
kubectl logs -f nom-du-pod -n namespace

# Logs avec nombre de lignes
kubectl logs --tail=100 nom-du-pod -n namespace

# Logs d'un deployment
kubectl logs deployment/vote -n voting
kubectl logs deployment/postgres -n bd
kubectl logs deployment/odoo -n odoo

# Logs d'un conteneur specifique (si multi-conteneur)
kubectl logs nom-du-pod -c nom-conteneur -n namespace
```

### Executer des commandes dans un pod

```bash
# Shell interactif
kubectl exec -it nom-du-pod -n namespace -- /bin/bash
kubectl exec -it nom-du-pod -n namespace -- /bin/sh

# Exemples TP-4
kubectl exec -it deployment/postgres -n bd -- psql -U postgres
kubectl exec -it deployment/redis -n voting -- redis-cli

# Commande simple
kubectl exec nom-du-pod -n namespace -- ls /app
```

### Supprimer des pods

```bash
# Supprimer un pod specifique
kubectl delete pod nom-du-pod -n namespace

# Supprimer tous les pods d'un namespace
kubectl delete pods --all -n namespace

# Forcer la suppression
kubectl delete pod nom-du-pod -n namespace --force --grace-period=0
```

---

## Gestion des Deployments

### Lister les deployments

```bash
# Deployments d'un namespace
kubectl get deployments -n bd
kubectl get deployments -n voting
kubectl get deployments -n odoo

# Tous les deployments
kubectl get deployments --all-namespaces
```

### Details et status

```bash
# Description complete
kubectl describe deployment vote -n voting

# Status du rollout
kubectl rollout status deployment/vote -n voting

# Historique des rollouts
kubectl rollout history deployment/vote -n voting
```

### Scaler un deployment

```bash
# Changer le nombre de replicas
kubectl scale deployment vote --replicas=3 -n voting
kubectl scale deployment result --replicas=2 -n voting

# Verifier
kubectl get pods -n voting -l app=vote
```

### Rollback

```bash
# Annuler le dernier rollout
kubectl rollout undo deployment/vote -n voting

# Revenir a une revision specifique
kubectl rollout undo deployment/vote --to-revision=2 -n voting
```

---

## Gestion des Services

### Lister les services

```bash
# Services d'un namespace
kubectl get services -n bd
kubectl get svc -n voting
kubectl get svc -n odoo

# Tous les services
kubectl get svc --all-namespaces

# Services avec details
kubectl get svc -o wide -n voting
```

### Details d'un service

```bash
# Description complete
kubectl describe svc vote -n voting
kubectl describe svc postgres -n bd

# Voir les endpoints
kubectl get endpoints -n voting
kubectl get endpoints vote -n voting
```

### Types de services

```bash
# Filtrer par type
kubectl get svc --all-namespaces | grep ClusterIP
kubectl get svc --all-namespaces | grep NodePort
kubectl get svc --all-namespaces | grep LoadBalancer
```

---

## Gestion des Ingress

### Lister les Ingress

```bash
# Tous les Ingress
kubectl get ingress --all-namespaces

# Ingress d'un namespace
kubectl get ingress -n bd
kubectl get ingress -n voting
kubectl get ingress -n odoo
```

### Details d'un Ingress

```bash
# Description complete
kubectl describe ingress pgadmin-ingress -n bd
kubectl describe ingress voting-app-ingress -n voting
kubectl describe ingress odoo-ingress -n odoo
```

### Ingress Controller

```bash
# Pods de l'Ingress Controller
kubectl get pods -n ingress-nginx

# Service de l'Ingress Controller
kubectl get svc -n ingress-nginx

# Logs de l'Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# NodePort de l'Ingress
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}'
```

---

## Gestion des Secrets

### Lister les secrets

```bash
# Secrets d'un namespace
kubectl get secrets -n bd
kubectl get secrets -n odoo
```

### Voir un secret

```bash
# Description (sans les valeurs)
kubectl describe secret postgres-secret -n bd

# Voir les valeurs encodees
kubectl get secret postgres-secret -n bd -o yaml

# Decoder une valeur
kubectl get secret postgres-secret -n bd -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

### Creer un secret

```bash
# Depuis des litteraux
kubectl create secret generic mon-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123 \
  -n namespace

# Depuis un fichier
kubectl create secret generic mon-secret \
  --from-file=config.txt \
  -n namespace
```

---

## Gestion des PV/PVC

### Lister les PersistentVolumes

```bash
# Tous les PV (non-namespace)
kubectl get pv

# Details d'un PV
kubectl describe pv postgres-pv
```

### Lister les PersistentVolumeClaims

```bash
# PVC d'un namespace
kubectl get pvc -n bd

# Details d'un PVC
kubectl describe pvc postgres-pvc -n bd
```

---

## Commandes Minikube

### Gestion du cluster

```bash
# Status de Minikube
minikube status

# Demarrer Minikube
sudo minikube start --driver=none --container-runtime=containerd --force

# Arreter Minikube
minikube stop

# Supprimer Minikube
sudo minikube delete --all --purge

# IP de Minikube
minikube ip
```

### Gestion des addons

```bash
# Liste des addons
minikube addons list

# Activer un addon
minikube addons enable ingress
minikube addons enable metallb

# Desactiver un addon
minikube addons disable metallb

# Configurer MetalLB
minikube addons configure metallb
```

### Dashboard

```bash
# Ouvrir le dashboard (si GUI disponible)
minikube dashboard

# URL du dashboard
minikube dashboard --url
```

---

## Commandes de Debug

### Diagnostiquer un pod

```bash
# Voir les events du pod
kubectl describe pod nom-du-pod -n namespace | tail -20

# Voir les events du namespace
kubectl get events -n voting --sort-by='.lastTimestamp'

# Voir les logs
kubectl logs nom-du-pod -n namespace

# Logs du conteneur precedent (si crash)
kubectl logs nom-du-pod -n namespace --previous
```

### Tester la connectivite

```bash
# Creer un pod de debug
kubectl run debug --rm -it --image=busybox -n voting -- /bin/sh

# Tester un service depuis le pod
wget -qO- http://vote:80
wget -qO- http://redis:6379
nslookup vote
nslookup postgres.bd.svc.cluster.local
```

### Port-forward pour debug local

```bash
# Forward un pod
kubectl port-forward pod/nom-du-pod 8080:80 -n namespace

# Forward un service
kubectl port-forward svc/vote 8080:80 -n voting
kubectl port-forward svc/pgadmin 8080:80 -n bd

# Forward en arriere-plan
kubectl port-forward svc/vote 8080:80 -n voting &
```

### Copier des fichiers

```bash
# Copier vers un pod
kubectl cp fichier.txt namespace/nom-du-pod:/chemin/destination

# Copier depuis un pod
kubectl cp namespace/nom-du-pod:/chemin/fichier ./fichier-local
```

---

## Commandes Rapides TP-4

### Verification globale

```bash
# Tout voir d'un coup
kubectl get all,ingress,pv,pvc,secrets --all-namespaces | grep -E "bd|voting|odoo|NAME"

# Status des pods
kubectl get pods -A | grep -E "bd|voting|odoo"

# Status des ingress
kubectl get ingress -A
```

### Tests rapides

```bash
# Obtenir le NodePort
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

# Tester les applications
curl -H "Host: vote.local" http://localhost:$NODEPORT
curl -H "Host: result.local" http://localhost:$NODEPORT
curl -H "Host: pgadmin.local" http://localhost:$NODEPORT
curl -H "Host: odoo.local" http://localhost:$NODEPORT
```

### Redemarrage rapide

```bash
# Redemarrer un deployment
kubectl rollout restart deployment/vote -n voting

# Redemarrer tous les deployments d'un namespace
kubectl rollout restart deployment -n voting
```

---

## Aliases Utiles

Ajouter dans `~/.bashrc`:

```bash
# Aliases kubectl
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods --all-namespaces'
alias kgs='kubectl get services'
alias kgi='kubectl get ingress'
alias kgn='kubectl get namespaces'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# Aliases TP-4
alias ktp4='kubectl get pods -A | grep -E "bd|voting|odoo"'
alias kingress='kubectl get ingress -A'

# Charger les aliases
source ~/.bashrc
```

---

## Auteur

Adalbert NANDA - Janvier 2026
