# 🔍 Checklist de Débogage Kubernetes

Guide complet des commandes de diagnostic et de résolution des problèmes pour Kubernetes/Minikube.

---

## 📋 Table des matières

1. [Diagnostic Système](#diagnostic-système)
2. [Vérification des Services](#vérification-des-services)
3. [Débogage Minikube](#débogage-minikube)
4. [Débogage Pods](#débogage-pods)
5. [Débogage Deployments](#débogage-deployments)
6. [Débogage Réseau](#débogage-réseau)
7. [Problèmes Courants](#problèmes-courants)

---

## 🖥️ Diagnostic Système

### Vérifier l'OS et la version
```bash
cat /etc/os-release
lsb_release -a
uname -a
```

### Vérifier les ressources système
```bash
# CPU et Mémoire
free -h
nproc
top
htop

# Espace disque
df -h
du -sh /var/lib/containerd
du -sh /var/lib/kubelet
```

### Vérifier les modules kernel
```bash
lsmod | grep br_netfilter
lsmod | grep overlay

# Charger si nécessaire
sudo modprobe br_netfilter
sudo modprobe overlay
```

### Vérifier sysctl
```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
```

---

## 🔧 Vérification des Services

### Containerd
```bash
# Statut
sudo systemctl status containerd

# Logs
sudo journalctl -xeu containerd -n 50 --no-pager
sudo journalctl -xeu containerd -f  # Suivi en temps réel

# Version
containerd --version
sudo ctr version

# Redémarrer
sudo systemctl restart containerd
```

### Kubelet
```bash
# Statut
sudo systemctl status kubelet

# Logs
sudo journalctl -xeu kubelet -n 50 --no-pager
sudo journalctl -xeu kubelet -f

# Redémarrer
sudo systemctl restart kubelet
```

### Docker (si utilisé avec cri-dockerd)
```bash
# Statut
sudo systemctl status docker

# Logs
sudo journalctl -xeu docker -n 50 --no-pager

# Tester
docker ps
docker info
```

### cri-dockerd (si Docker est utilisé)
```bash
# Statut
sudo systemctl status cri-dockerd
sudo systemctl status cri-docker.socket

# Logs
sudo journalctl -xeu cri-dockerd -n 50 --no-pager

# Vérifier le socket
ls -la /var/run/cri-dockerd.sock
```

---

## 🎡 Débogage Minikube

### Statut général
```bash
minikube status
minikube version
```

### Profils
```bash
# Lister les profils
minikube profile list

# Changer de profil
minikube profile <nom>
```

### Logs
```bash
# Logs généraux
minikube logs

# Sauvegarder les logs dans un fichier
minikube logs --file=logs.txt

# Logs d'un composant spécifique
minikube logs --component=kubelet
minikube logs --component=apiserver
```

### Configuration
```bash
# Voir la configuration
minikube config view

# IP du cluster
minikube ip

# Informations du cluster
kubectl cluster-info
kubectl cluster-info dump > cluster-dump.txt
```

### SSH dans le nœud
```bash
minikube ssh

# Une fois connecté:
docker ps  # ou
crictl ps
```

### Dashboard
```bash
# Lancer le dashboard
minikube dashboard

# URL uniquement
minikube dashboard --url
```

### Addons
```bash
# Lister les addons
minikube addons list

# Activer un addon
minikube addons enable metrics-server
minikube addons enable dashboard

# Désactiver un addon
minikube addons disable <addon>
```

### Redémarrage/Nettoyage
```bash
# Arrêter
minikube stop

# Supprimer le cluster
minikube delete

# Supprimer tous les profils
minikube delete --all --purge

# Nettoyer complètement
sudo rm -rf ~/.minikube
sudo rm -rf /root/.minikube
sudo rm -rf /tmp/minikube*
sudo rm -rf /tmp/juju-*
```

---

## 🐳 Débogage Pods

### Lister les pods
```bash
# Tous les namespaces
kubectl get pods -A
kubectl get pods --all-namespaces

# Namespace spécifique
kubectl get pods -n kube-system
kubectl get pods -n default

# Avec plus de détails
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json

# Filtrer par label
kubectl get pods -l app=nginx
kubectl get pods -l 'environment in (prod,staging)'

# Trier
kubectl get pods --sort-by=.metadata.creationTimestamp
kubectl get pods --sort-by=.status.startTime
```

### Surveiller les pods en temps réel
```bash
# Watch mode
kubectl get pods -w
kubectl get pods -A -w

# Avec watch système
watch -n 1 kubectl get pods
```

### Décrire un pod
```bash
# Détails complets
kubectl describe pod <pod-name>

# Voir les événements
kubectl describe pod <pod-name> | grep -A 10 Events

# Voir l'image utilisée
kubectl describe pod <pod-name> | grep Image
```

### Logs des pods
```bash
# Logs du pod
kubectl logs <pod-name>

# Logs en temps réel
kubectl logs -f <pod-name>

# Logs d'un conteneur spécifique (si multi-conteneurs)
kubectl logs <pod-name> -c <container-name>

# Logs du conteneur précédent (si crash)
kubectl logs <pod-name> --previous

# Dernières 50 lignes
kubectl logs <pod-name> --tail=50

# Logs avec timestamp
kubectl logs <pod-name> --timestamps

# Logs de tous les pods d'un deployment
kubectl logs -l app=nginx --all-containers=true
```

### Exécuter des commandes dans un pod
```bash
# Shell interactif
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh

# Commande unique
kubectl exec <pod-name> -- ls -la /
kubectl exec <pod-name> -- cat /etc/resolv.conf
kubectl exec <pod-name> -- env

# Avec un conteneur spécifique
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash
```

### Tester la connectivité réseau
```bash
# Ping
kubectl exec <pod-name> -- ping -c 3 google.com

# DNS
kubectl exec <pod-name> -- nslookup kubernetes.default

# Curl
kubectl exec <pod-name> -- curl http://service-name:port
```

### Port-forward
```bash
# Exposer un port localement
kubectl port-forward <pod-name> 8080:80

# Écouter sur toutes les interfaces
kubectl port-forward <pod-name> 8080:80 --address 0.0.0.0

# Avec un service
kubectl port-forward service/<service-name> 8080:80
```

### Copier des fichiers
```bash
# Du pod vers local
kubectl cp <pod-name>:/path/to/file ./local-file

# Du local vers pod
kubectl cp ./local-file <pod-name>:/path/to/file

# Avec namespace
kubectl cp <namespace>/<pod-name>:/path/to/file ./local-file
```

### Supprimer des pods
```bash
# Supprimer un pod
kubectl delete pod <pod-name>

# Forcer la suppression
kubectl delete pod <pod-name> --force --grace-period=0

# Supprimer par label
kubectl delete pods -l app=nginx

# Supprimer tous les pods d'un namespace
kubectl delete pods --all -n <namespace>
```

---

## 📦 Débogage Deployments

### Lister les deployments
```bash
kubectl get deployments
kubectl get deploy -A
kubectl get deploy -o wide
```

### Décrire un deployment
```bash
kubectl describe deployment <deployment-name>

# Voir les conditions
kubectl describe deployment <deployment-name> | grep Conditions -A 5

# Voir la stratégie de rollout
kubectl describe deployment <deployment-name> | grep Strategy -A 3
```

### Vérifier les ReplicaSets
```bash
# Lister
kubectl get replicaset
kubectl get rs

# Décrire
kubectl describe rs <replicaset-name>

# Voir l'historique
kubectl get rs -o wide
```

### Rollout
```bash
# Voir le statut d'un rollout
kubectl rollout status deployment/<deployment-name>

# Voir l'historique des rollouts
kubectl rollout history deployment/<deployment-name>

# Voir les détails d'une révision
kubectl rollout history deployment/<deployment-name> --revision=2

# Faire un rollback
kubectl rollout undo deployment/<deployment-name>

# Rollback vers une révision spécifique
kubectl rollout undo deployment/<deployment-name> --to-revision=2

# Pause/Resume d'un rollout
kubectl rollout pause deployment/<deployment-name>
kubectl rollout resume deployment/<deployment-name>

# Redémarrer un deployment
kubectl rollout restart deployment/<deployment-name>
```

### Scaler un deployment
```bash
# Manuellement
kubectl scale deployment <deployment-name> --replicas=3

# Autoscaling
kubectl autoscale deployment <deployment-name> --min=2 --max=10 --cpu-percent=80

# Voir les HPA (Horizontal Pod Autoscaler)
kubectl get hpa
```

### Mettre à jour l'image
```bash
kubectl set image deployment/<deployment-name> <container-name>=<new-image>:<tag>

# Exemple
kubectl set image deployment/nginx-deployment nginx=nginx:latest
```

---

## 🌐 Débogage Réseau

### Services
```bash
# Lister les services
kubectl get services
kubectl get svc -A

# Décrire un service
kubectl describe service <service-name>

# Voir les endpoints
kubectl get endpoints
kubectl get ep <service-name>
```

### DNS
```bash
# Tester la résolution DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Voir les logs de CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns

# Décrire le service DNS
kubectl describe svc kube-dns -n kube-system
```

### NetworkPolicies
```bash
kubectl get networkpolicies
kubectl get netpol -A
kubectl describe netpol <policy-name>
```

### CNI
```bash
# Vérifier les pods CNI
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave|cilium'

# Logs du plugin CNI
kubectl logs -n kube-system <cni-pod-name>
```

### Connectivité entre pods
```bash
# Créer un pod de test
kubectl run busybox --image=busybox --rm -it --restart=Never -- /bin/sh

# Une fois dans le pod:
wget -O- http://<service-name>:<port>
nc -zv <service-name> <port>
```

---

## ⚠️ Problèmes Courants

### Pod en CrashLoopBackOff
```bash
# Voir les logs
kubectl logs <pod-name> --previous

# Décrire pour voir les événements
kubectl describe pod <pod-name>

# Vérifier l'image
kubectl describe pod <pod-name> | grep Image

# Vérifier les ressources
kubectl describe pod <pod-name> | grep -A 5 Limits
```

### Pod en ImagePullBackOff
```bash
# Vérifier le nom de l'image
kubectl describe pod <pod-name> | grep Image

# Vérifier les secrets
kubectl get secrets
kubectl describe secret <secret-name>

# Tester manuellement
docker pull <image-name>
```

### Pod en Pending
```bash
# Vérifier les ressources disponibles
kubectl describe nodes
kubectl top nodes

# Vérifier les événements
kubectl get events --sort-by=.metadata.creationTimestamp

# Vérifier les taints
kubectl describe nodes | grep Taints
```

### Problèmes de permissions kubectl
```bash
# Vérifier le fichier kubeconfig
cat ~/.kube/config

# Vérifier les permissions
ls -la ~/.kube/config
ls -la ~/.minikube/

# Corriger les permissions
sudo chown -R $USER:$USER ~/.kube
sudo chown -R $USER:$USER ~/.minikube
chmod 600 ~/.kube/config

# Corriger les chemins
sed -i "s|/root|$HOME|g" ~/.kube/config
```

### crictl ne fonctionne pas
```bash
# Vérifier la configuration
cat /etc/crictl.yaml

# Créer/corriger la configuration
sudo tee /etc/crictl.yaml > /dev/null <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Tester
sudo crictl version
sudo crictl info
sudo crictl ps
sudo crictl images
```

### Containerd ne démarre pas
```bash
# Voir les logs
sudo journalctl -xeu containerd -n 100

# Vérifier la configuration
sudo cat /etc/containerd/config.toml | grep -i systemdcgroup

# Reconfigurer
sudo systemctl stop containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
```

### Minikube ne démarre pas
```bash
# Voir les logs détaillés
minikube logs

# Nettoyer et redémarrer
minikube delete --all --purge
sudo rm -rf ~/.minikube /root/.minikube /tmp/minikube* /tmp/juju-*
sudo sysctl fs.protected_regular=0
minikube start --driver=none --container-runtime=containerd --force

# Vérifier les prérequis
which kubectl
which kubeadm
which kubelet
systemctl status containerd
```

---

## 🛠️ Commandes Utiles Générales

### Tout voir d'un coup
```bash
kubectl get all -A
kubectl get events -A --sort-by=.metadata.creationTimestamp
kubectl top nodes
kubectl top pods -A
```

### Rechercher
```bash
# Chercher dans tous les objets
kubectl get all -A | grep <terme>

# Chercher dans les événements
kubectl get events -A | grep <pod-name>
```

### Export YAML
```bash
# Exporter un objet existant
kubectl get pod <pod-name> -o yaml > pod.yaml
kubectl get deployment <deploy-name> -o yaml > deployment.yaml
```

### Dry-run
```bash
# Tester sans créer
kubectl apply -f pod.yml --dry-run=client
kubectl apply -f pod.yml --dry-run=server
```

### Explain (Documentation)
```bash
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers
kubectl explain deployment.spec.strategy
```

---

## 📊 Monitoring

### Metrics Server
```bash
# Installer
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Utiliser
kubectl top nodes
kubectl top pods
kubectl top pods --containers
```

### Événements
```bash
# Tous les événements
kubectl get events -A

# Triés par date
kubectl get events --sort-by=.metadata.creationTimestamp

# Filtrés par type
kubectl get events --field-selector type=Warning
```

---

## 💾 Backup/Restore

### Backup des ressources
```bash
# Backup de tous les objets
kubectl get all -A -o yaml > backup-all.yaml

# Backup par type
kubectl get deployments -A -o yaml > deployments-backup.yaml
kubectl get services -A -o yaml > services-backup.yaml
kubectl get configmaps -A -o yaml > configmaps-backup.yaml
kubectl get secrets -A -o yaml > secrets-backup.yaml
```

---

## 🔑 Astuces Supplémentaires

### Alias utiles
```bash
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kga='kubectl get all -A'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kdel='kubectl delete'
```

### Watch avec couleurs
```bash
watch -c -n 1 kubectl get pods --sort-by=.status.startTime
```

### JSON Path
```bash
# Extraire des infos spécifiques
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
```

---

**Note**: Cette checklist est un guide de référence. Adaptez les commandes selon votre situation spécifique.
