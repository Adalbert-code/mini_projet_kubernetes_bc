# 📦 Installation Kubernetes/Minikube - Guide Complet

Guide d'installation et de configuration de Kubernetes avec Minikube sur Ubuntu 22.04 LTS.

---

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation Rapide](#installation-rapide)
3. [Installation Détaillée](#installation-détaillée)
4. [Vérification](#vérification)
5. [Premiers Pas](#premiers-pas)
6. [Dépannage](#dépannage)

---

## 💻 Prérequis

### Matériel
- **CPU** : 4 cores minimum (recommandé)
- **RAM** : 6 GB minimum (8 GB recommandé)
- **Disque** : 40 GB minimum d'espace libre

### Logiciels
- **OS** : Ubuntu 22.04 LTS (Jammy) - **OBLIGATOIRE**
  - Autres versions supportées : 20.04 LTS (Focal), 24.04 LTS (Noble)
- **VirtualBox** : Pour Vagrant (si utilisation de VM)
- **Vagrant** : 2.3.0 ou supérieur (si utilisation de VM)

### Réseau
- Connexion Internet pour télécharger les images Docker
- Port 192.168.56.10 disponible (pour réseau privé Vagrant)

---

## 🚀 Installation Rapide

### Option 1 : Installation Automatique avec Vagrant

```bash
# 1. Cloner le repository
git clone <votre-repo>
cd kubernetes-training/tp-2

# 2. Vérifier que les fichiers sont présents
ls -la Vagrantfile install_minikube.sh

# 3. Démarrer la VM (l'installation est automatique)
vagrant up

# 4. Se connecter à la VM
vagrant ssh

# 5. Vérifier l'installation
kubectl get nodes
minikube status
```

**Durée estimée** : 10-15 minutes (selon la connexion Internet)

---

### Option 2 : Installation Manuelle

```bash
# 1. Télécharger le script d'installation
wget https://raw.githubusercontent.com/<votre-repo>/install_minikube_FINAL.sh
chmod +x install_minikube_FINAL.sh

# 2. Exécuter le script (en tant que root)
sudo ./install_minikube_FINAL.sh

# 3. Vérifier
kubectl get nodes
minikube status
```

---

## 📚 Installation Détaillée

### Étape 1 : Préparation du Système

```bash
# Mise à jour du système
sudo apt-get update
sudo apt-get upgrade -y

# Installation des outils de base
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    software-properties-common \
    git \
    wget
```

### Étape 2 : Installation de Containerd

```bash
# Ajout du repository Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation
sudo apt-get update
sudo apt-get install -y containerd.io

# Configuration pour Kubernetes
sudo systemctl stop containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Démarrage
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### Étape 3 : Configuration Réseau

```bash
# Modules kernel
sudo modprobe br_netfilter

# Configuration sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo sysctl --system
```

### Étape 4 : Installation de Kubernetes

```bash
# Variables
KUBERNETES_VERSION="1.31.0"
K8S_REPO_VERSION="1.31"

# Ajout du repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_REPO_VERSION}/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/v${K8S_REPO_VERSION}/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

# Installation
sudo apt-get update
sudo apt-get install -y \
    kubelet=${KUBERNETES_VERSION}-1.1 \
    kubeadm=${KUBERNETES_VERSION}-1.1 \
    kubectl=${KUBERNETES_VERSION}-1.1

# Hold des packages
sudo apt-mark hold kubelet kubeadm kubectl

# Activation
sudo systemctl enable kubelet
```

### Étape 5 : Installation de Minikube

```bash
# Téléchargement
MINIKUBE_VERSION="v1.34.0"
curl -LO https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64

# Installation
sudo install minikube-linux-amd64 /usr/local/bin/minikube
sudo chmod +x /usr/local/bin/minikube

# Vérification
minikube version
```

### Étape 6 : Installation des Outils

```bash
# crictl (v1.32.0 pour compatibilité avec containerd 2.2.1)
CRICTL_VERSION="v1.32.0"
cd /tmp
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
sudo tar -zxf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin

# Configuration crictl
sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Plugins CNI
CNI_VERSION="v1.5.1"
curl -LO https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-${CNI_VERSION}.tgz
```

### Étape 7 : Démarrage de Minikube

```bash
# Correctif de permissions
sudo sysctl fs.protected_regular=0

# Démarrage
sudo minikube start \
    --driver=none \
    --kubernetes-version=v1.31.0 \
    --container-runtime=containerd \
    --force

# Configuration des permissions pour utilisateur non-root
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R $USER:$USER ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config
chmod 600 ~/.kube/config
```

### Étape 8 : Configuration du Shell

```bash
# Completion bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# Aliases utiles
cat >> ~/.bashrc <<'EOF'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kga='kubectl get all -A'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
EOF

# Appliquer
source ~/.bashrc
```

---

## ✅ Vérification

### Vérifier l'installation

```bash
# Version des composants
kubectl version --client
minikube version
containerd --version
crictl --version

# Statut du cluster
minikube status
kubectl cluster-info

# Voir les nœuds
kubectl get nodes

# Voir les pods système
kubectl get pods -A

# Tester crictl
sudo crictl info
sudo crictl ps
```

### Résultat attendu

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   5m    v1.31.0
```

Tous les pods dans `kube-system` doivent être `Running`.

---

## 🎯 Premiers Pas

### Déployer votre premier pod

```bash
# Créer un pod nginx
kubectl run nginx --image=nginx

# Vérifier
kubectl get pods

# Voir les détails
kubectl describe pod nginx

# Voir les logs
kubectl logs nginx

# Supprimer
kubectl delete pod nginx
```

### Créer un deployment

```bash
# Créer un deployment
kubectl create deployment nginx --image=nginx --replicas=3

# Vérifier
kubectl get deployments
kubectl get pods

# Scaler
kubectl scale deployment nginx --replicas=5

# Supprimer
kubectl delete deployment nginx
```

### Exposer un service

```bash
# Créer un deployment
kubectl create deployment webapp --image=nginx

# Exposer le service
kubectl expose deployment webapp --port=80 --type=NodePort

# Voir le service
kubectl get services

# Accéder au service
minikube service webapp --url
curl $(minikube service webapp --url)
```

### Utiliser le dashboard

```bash
# Lancer le dashboard
minikube dashboard

# Ou obtenir l'URL
minikube dashboard --url
```

---

## 🔧 Configuration Avancée

### Activer des addons

```bash
# Lister les addons disponibles
minikube addons list

# Activer metrics-server
minikube addons enable metrics-server

# Activer le dashboard
minikube addons enable dashboard

# Vérifier
kubectl top nodes
kubectl top pods -A
```

### Configurer l'autocomplétion

```bash
# Pour bash (déjà fait dans le script)
source <(kubectl completion bash)
complete -F __start_kubectl k

# Pour zsh
source <(kubectl completion zsh)
```

### Persister les données

```bash
# Créer un PersistentVolume
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
EOF
```

---

## 🐛 Dépannage

### Problème : kubectl ne fonctionne pas

```bash
# Vérifier la configuration
kubectl config view
kubectl config current-context

# Corriger les permissions
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R $USER:$USER ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config
```

### Problème : Pods ne démarrent pas

```bash
# Voir les événements
kubectl get events --sort-by=.metadata.creationTimestamp

# Voir les logs
kubectl logs <pod-name>
kubectl describe pod <pod-name>

# Vérifier les ressources
kubectl top nodes
kubectl top pods -A
```

### Problème : Minikube ne démarre pas

```bash
# Voir les logs
minikube logs

# Nettoyer et redémarrer
sudo minikube delete --all --purge
sudo rm -rf ~/.minikube /root/.minikube /tmp/minikube*
sudo sysctl fs.protected_regular=0
sudo minikube start --driver=none --container-runtime=containerd --force
```

### Voir le guide complet de dépannage

Consultez [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) pour plus de solutions.

---

## 📚 Ressources Supplémentaires

### Documentation
- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Minikube](https://minikube.sigs.k8s.io/docs/)
- [Tutoriels Kubernetes](https://kubernetes.io/docs/tutorials/)

### Guides fournis
- [CHECKLIST_DEBOGAGE.md](./CHECKLIST_DEBOGAGE.md) - Commandes de diagnostic
- [GUIDE_COMMANDES_K8S.md](./GUIDE_COMMANDES_K8S.md) - Référence des commandes
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Solutions aux problèmes courants

### Communauté
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/kubernetes)
- [Reddit r/kubernetes](https://www.reddit.com/r/kubernetes/)

---

## 🎓 Prochaines Étapes

1. Suivre les TPs Kubernetes fournis
2. Déployer des applications réelles
3. Explorer les concepts avancés (Ingress, StatefulSets, etc.)
4. Pratiquer avec des projets personnels

---

## 📝 Notes Importantes

### ⚠️ Limitations du driver "none"

Le driver `none` utilisé par Minikube :
- Exécute Kubernetes directement sur la machine hôte
- Nécessite des privilèges root
- Ne fournit pas d'isolation
- Idéal pour l'apprentissage et le développement

### 🔒 Sécurité

Pour un environnement de production :
- Utilisez un vrai cluster Kubernetes
- Configurez RBAC correctement
- Utilisez des NetworkPolicies
- Activez l'audit logging

### 💾 Sauvegarde

Pour sauvegarder votre configuration :
```bash
# Backup des ressources
kubectl get all -A -o yaml > backup-$(date +%Y%m%d).yaml

# Backup de la config
cp -r ~/.kube ~/.kube-backup
cp -r ~/.minikube ~/.minikube-backup
```

---

## 🆘 Support

En cas de problème :

1. Consultez [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Vérifiez les logs : `minikube logs`
3. Consultez la [documentation officielle](https://kubernetes.io/docs/)
4. Ouvrez une issue sur GitHub

---

**Version** : 3.0 FINALE
**Date** : Janvier 2026
**OS Supporté** : Ubuntu 22.04 LTS (Jammy)
**Runtime** : Containerd
**Kubernetes** : v1.31.0
