# TP-4 Avance : Guide d'Installation Complete

Guide complet pour reinstaller et deployer le TP-4 apres destruction de la VM.

---

## Table des matieres

1. [Pre-requis](#pre-requis)
2. [Installation de la VM](#installation-de-la-vm)
3. [Configuration de Kubernetes](#configuration-de-kubernetes)
4. [Deploiement du TP-4](#deploiement-du-tp-4)
5. [Verification Post-Installation](#verification-post-installation)
6. [Acces aux Applications](#acces-aux-applications)

---

## Pre-requis

### Sur la machine hote (Windows)

- VirtualBox installe
- Vagrant installe
- Git installe
- Minimum 4 Go de RAM disponible
- Minimum 20 Go d'espace disque

### Verification des pre-requis

```powershell
# Verifier VirtualBox
vboxmanage --version

# Verifier Vagrant
vagrant --version

# Verifier Git
git --version
```

---

## Installation de la VM

### Etape 1 : Cloner le depot (si necessaire)

```powershell
cd C:\Users\adaln\EAZYTRAINING\DevOpsBootCamps\kubernetes
git clone https://github.com/Adalbert-code/kubernetes_training.git
cd kubernetes-training
```

### Etape 2 : Demarrer la VM

```powershell
cd C:\Users\adaln\EAZYTRAINING\DevOpsBootCamps\kubernetes\kubernetes-training
vagrant up
```

### Etape 3 : Se connecter a la VM

```powershell
vagrant ssh
```

---

## Configuration de Kubernetes

### Etape 1 : Demarrer Minikube

```bash
# Demarrer Minikube avec containerd
sudo minikube start \
    --driver=none \
    --kubernetes-version=v1.31.0 \
    --container-runtime=containerd \
    --force

# Configurer les permissions
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R vagrant:vagrant ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config

# Verifier
kubectl get nodes
```

### Etape 2 : Activer les Addons necessaires

```bash
# Activer Ingress Controller
minikube addons enable ingress

# Attendre que l'Ingress Controller soit pret
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Activer MetalLB
minikube addons enable metallb

# Verifier les addons
minikube addons list | grep -E "ingress|metallb"
```

---

## Deploiement du TP-4

### Option 1 : Deploiement automatique (recommande)

```bash
# Aller dans le repertoire tp-4
cd /vagrant/tp-4

# Rendre le script executable
chmod +x deploy-all.sh

# Executer le deploiement complet
./deploy-all.sh
```

### Option 2 : Deploiement manuel etape par etape

#### 1. Deployer PostgreSQL + PgAdmin (namespace: bd)

```bash
cd /vagrant/tp-4

# Creer le namespace
kubectl apply -f postgresql/namespace.yaml

# Deployer les ressources
kubectl apply -f postgresql/postgres-secret.yaml
kubectl apply -f postgresql/postgres-pv.yaml
kubectl apply -f postgresql/postgres-deployment.yaml
kubectl apply -f postgresql/pgadmin-deployment.yaml

# Deployer l'Ingress
kubectl apply -f ingress/pgadmin-ingress.yaml
```

#### 2. Deployer Voting App (namespace: voting)

```bash
# Creer le namespace
kubectl apply -f voting-app/namespace.yaml

# Deployer les composants
kubectl apply -f voting-app/redis-deployment.yaml
kubectl apply -f voting-app/db-deployment.yaml
kubectl apply -f voting-app/vote-deployment.yaml
kubectl apply -f voting-app/result-deployment.yaml
kubectl apply -f voting-app/worker-deployment.yaml

# Deployer l'Ingress
kubectl apply -f ingress/voting-app-ingress.yaml
```

#### 3. Deployer Odoo ERP (namespace: odoo)

```bash
# Creer le namespace et les secrets
kubectl apply -f odoo/namespace.yaml
kubectl apply -f odoo/odoo-secret.yaml

# Deployer PostgreSQL pour Odoo
kubectl apply -f odoo/odoo-postgres-deployment.yaml

# Deployer Odoo
kubectl apply -f odoo/odoo-deployment.yaml

# Deployer l'Ingress
kubectl apply -f ingress/odoo-ingress.yaml
```

---

## Verification Post-Installation

### Verifier les namespaces

```bash
kubectl get namespaces | grep -E "bd|voting|odoo"
```

**Resultat attendu:**
```
bd              Active   XXm
odoo            Active   XXm
voting          Active   XXm
```

### Verifier les pods

```bash
kubectl get pods --all-namespaces | grep -E "bd|voting|odoo"
```

**Tous les pods doivent etre en "Running"**

### Verifier les services

```bash
kubectl get svc --all-namespaces | grep -E "bd|voting|odoo"
```

**Tous les services doivent etre en "ClusterIP"**

### Verifier les Ingress

```bash
kubectl get ingress --all-namespaces
```

**Resultat attendu:**
```
NAMESPACE   NAME                  CLASS   HOSTS                       ADDRESS   PORTS
bd          pgadmin-ingress       nginx   pgadmin.local               ...       80
odoo        odoo-ingress          nginx   odoo.local                  ...       80
voting      voting-app-ingress    nginx   vote.local,result.local     ...       80
```

### Verifier l'Ingress Controller

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## Acces aux Applications

### Etape 1 : Obtenir l'IP de la VM

```bash
# Dans la VM
ip addr show eth1 | grep inet
# ou
hostname -I
```

**IP attendue:** `192.168.56.10`

### Etape 2 : Obtenir le NodePort de l'Ingress

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

**Port HTTP:** `32655` (ou autre NodePort)

### Etape 3 : Configurer le fichier hosts (Windows)

Ouvrir PowerShell en Administrateur:
```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

Ajouter ces lignes:
```
192.168.56.10 pgadmin.local
192.168.56.10 vote.local
192.168.56.10 result.local
192.168.56.10 odoo.local
```

### Etape 4 : Acceder aux applications

| Application | URL | Identifiants |
|-------------|-----|--------------|
| Vote | http://vote.local:32655 | - |
| Result | http://result.local:32655 | - |
| PgAdmin | http://pgadmin.local:32655 | admin@local.dev / admin123 |
| Odoo | http://odoo.local:32655 | (configurer au premier lancement) |

### Alternative : Test avec curl (sans modifier hosts)

```bash
# Depuis la VM
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

# Test Vote
curl -H "Host: vote.local" http://localhost:$NODEPORT

# Test Result
curl -H "Host: result.local" http://localhost:$NODEPORT

# Test PgAdmin
curl -H "Host: pgadmin.local" http://localhost:$NODEPORT

# Test Odoo
curl -H "Host: odoo.local" http://localhost:$NODEPORT
```

---

## Resume des Commandes d'Installation

```bash
# === DANS LA VM ===

# 1. Demarrer Minikube
sudo minikube start --driver=none --kubernetes-version=v1.31.0 --container-runtime=containerd --force
sudo cp -r /root/.kube ~/.kube && sudo chown -R vagrant:vagrant ~/.kube
sed -i "s|/root|$HOME|g" ~/.kube/config

# 2. Activer les addons
minikube addons enable ingress
minikube addons enable metallb
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# 3. Deployer tout
cd /vagrant/tp-4
chmod +x deploy-all.sh
./deploy-all.sh

# 4. Verifier
kubectl get pods --all-namespaces | grep -E "bd|voting|odoo"
kubectl get ingress --all-namespaces
```

---

## Auteur

Adalbert NANDA - Janvier 2026
