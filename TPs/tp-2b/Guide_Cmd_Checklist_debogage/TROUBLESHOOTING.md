# 🔧 Guide de Dépannage Kubernetes

Solutions aux problèmes courants rencontrés lors de l'installation et l'utilisation de Kubernetes/Minikube.

---

## 📋 Table des matières

1. [Problèmes d'Installation](#problèmes-dinstallation)
2. [Problèmes de Démarrage Minikube](#problèmes-de-démarrage-minikube)
3. [Problèmes kubectl](#problèmes-kubectl)
4. [Problèmes de Pods](#problèmes-de-pods)
5. [Problèmes de Réseau](#problèmes-de-réseau)
6. [Problèmes de Performance](#problèmes-de-performance)

---

## ⚙️ Problèmes d'Installation

### Problème : cri-dockerd incompatible avec Docker

**Symptômes :**
```
failed to get docker version from dockerd: client version 1.43 is too old. 
Minimum supported API version is 1.44
```

**Solution :**
Utiliser containerd au lieu de Docker + cri-dockerd :

```bash
# Configuration de containerd
sudo systemctl stop containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Configuration crictl
sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Démarrer Minikube
sudo minikube start --driver=none --container-runtime=containerd --force
```

---

### Problème : crictl incompatible avec containerd

**Symptômes :**
```
unmarshal status info JSON: json: cannot unmarshal string into Go value of type map[string]interface {}
```

**Cause :**
crictl v1.31.0 n'est pas compatible avec containerd 2.2.1

**Solution :**
Mettre à jour crictl vers v1.32.0 ou plus récent :

```bash
cd /tmp
VERSION="v1.32.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
sudo crictl version
```

---

### Problème : cri-dockerd socket échoue

**Symptômes :**
```
cri-docker.socket: Socket service cri-docker.service not loaded, refusing
```

**Cause :**
Incohérence entre le nom du service dans le fichier socket et le nom réel du service

**Solution :**
```bash
# Corriger le fichier socket
sudo sed -i 's/PartOf=cri-docker.service/PartOf=cri-dockerd.service/g' /etc/systemd/system/cri-docker.socket
sudo systemctl daemon-reload
sudo systemctl start cri-docker.socket
sudo systemctl start cri-dockerd.service
```

---

### Problème : Plugins CNI manquants

**Symptômes :**
```
no network config found in /etc/cni/net.d
```

**Solution :**
```bash
cd /tmp
CNI_VERSION="v1.5.1"
curl -LO "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf "cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
```

---

## 🚀 Problèmes de Démarrage Minikube

### Problème : Erreur de permissions "juju lock"

**Symptômes :**
```
boot lock: unable to open /tmp/juju-mk...: permission denied
```

**Solution :**
```bash
# Appliquer le correctif
sudo sysctl fs.protected_regular=0

# Nettoyer les fichiers temporaires
sudo rm -rf /tmp/juju-*
sudo rm -rf /tmp/minikube*

# Redémarrer
sudo minikube delete
sudo minikube start --driver=none --container-runtime=containerd --force
```

---

### Problème : Minikube démarre mais kubectl échoue

**Symptômes :**
```
The connection to the server localhost:8080 was refused
```

**Cause :**
kubectl n'est pas configuré ou les permissions ne sont pas correctes

**Solution :**
```bash
# Copier la configuration depuis root
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R $USER:$USER ~/.kube
sudo chown -R $USER:$USER ~/.minikube

# Corriger les chemins
sed -i "s|/root|$HOME|g" ~/.kube/config
chmod 600 ~/.kube/config

# Vérifier
kubectl get nodes
```

---

### Problème : Containerd plugin CRI désactivé

**Symptômes :**
```
disabled_plugins = ["cri"]
```

**Cause :**
La configuration par défaut de containerd avec Docker désactive le plugin CRI

**Solution :**
```bash
# Reconfigurer containerd
sudo systemctl stop containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
```

---

### Problème : Minikube très lent au démarrage

**Cause :**
Ressources insuffisantes ou problèmes réseau

**Solution :**
```bash
# Vérifier les ressources
free -h
nproc

# Augmenter les ressources dans Vagrantfile
v.memory = 6144  # 6GB minimum
v.cpus = 4       # 4 CPUs minimum

# Redémarrer la VM
vagrant reload
```

---

## 🔐 Problèmes kubectl

### Problème : Erreur de certificats

**Symptômes :**
```
unable to read client-cert /root/.minikube/profiles/minikube/client.crt: permission denied
```

**Solution :**
```bash
# Copier les certificats
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R $USER:$USER ~/.minikube

# Mettre à jour les chemins
sed -i "s|/root|$HOME|g" ~/.kube/config
```

---

### Problème : Contexte kubectl incorrect

**Symptômes :**
kubectl pointe vers le mauvais cluster

**Solution :**
```bash
# Voir les contextes
kubectl config get-contexts

# Changer de contexte
kubectl config use-context minikube

# Vérifier
kubectl config current-context
```

---

### Problème : kubectl lent

**Cause :**
Problèmes de DNS ou de cache

**Solution :**
```bash
# Nettoyer le cache
rm -rf ~/.kube/cache
rm -rf ~/.kube/http-cache

# Vérifier la résolution DNS
cat /etc/resolv.conf
```

---

## 🐳 Problèmes de Pods

### Problème : Pod en CrashLoopBackOff

**Diagnostic :**
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

**Causes courantes :**
1. **Erreur d'application** : Vérifier les logs
2. **Commande incorrecte** : Vérifier la commande de démarrage
3. **Dépendances manquantes** : Vérifier l'image
4. **Problèmes de permissions** : Vérifier securityContext

**Solutions :**
```bash
# Vérifier la commande
kubectl get pod <pod-name> -o yaml | grep -A 5 command

# Tester l'image localement
docker run -it <image> /bin/sh

# Vérifier les variables d'environnement
kubectl describe pod <pod-name> | grep -A 10 Environment
```

---

### Problème : Pod en ImagePullBackOff

**Causes courantes :**
1. Nom d'image incorrect
2. Image privée sans credentials
3. Problèmes réseau

**Solutions :**
```bash
# Vérifier le nom de l'image
kubectl describe pod <pod-name> | grep Image

# Tester le pull manuellement
docker pull <image-name>

# Pour images privées, créer un secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<password>

# Utiliser le secret dans le pod
spec:
  imagePullSecrets:
  - name: regcred
```

---

### Problème : Pod en Pending

**Causes courantes :**
1. Ressources insuffisantes
2. Pas de nœud disponible
3. Volume non disponible

**Diagnostic :**
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe nodes
kubectl top nodes
```

**Solutions :**
```bash
# Vérifier les ressources disponibles
kubectl top nodes

# Vérifier les taints
kubectl describe nodes | grep -A 5 Taints

# Vérifier les PVC
kubectl get pvc

# Réduire les ressources demandées
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
```

---

### Problème : Pod en ContainerCreating (trop long)

**Diagnostic :**
```bash
kubectl describe pod <pod-name>
kubectl get events | grep <pod-name>
```

**Causes courantes :**
1. Téléchargement d'image en cours
2. Problèmes de volume
3. Problèmes CNI

**Solutions :**
```bash
# Vérifier le pull d'image
kubectl describe pod <pod-name> | grep -A 5 Events

# Vérifier les volumes
kubectl describe pod <pod-name> | grep -A 10 Volumes

# Vérifier les logs CNI
kubectl logs -n kube-system -l k8s-app=calico-node  # ou autre CNI
```

---

## 🌐 Problèmes de Réseau

### Problème : Impossible d'accéder à un Service

**Diagnostic :**
```bash
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpoints <service-name>
```

**Solutions :**
```bash
# Vérifier que les endpoints existent
kubectl get ep <service-name>

# Si pas d'endpoints, vérifier les labels
kubectl get pods --show-labels
kubectl describe svc <service-name> | grep Selector

# Tester depuis un pod
kubectl run test --image=busybox --rm -it --restart=Never -- wget -O- http://<service-name>
```

---

### Problème : DNS ne fonctionne pas

**Diagnostic :**
```bash
# Tester la résolution DNS
kubectl run dnstest --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Vérifier CoreDNS
kubectl get pods -n kube-system | grep coredns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**Solutions :**
```bash
# Redémarrer CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Vérifier la configuration
kubectl get configmap coredns -n kube-system -o yaml
```

---

### Problème : Port-forward ne fonctionne pas

**Solutions :**
```bash
# Vérifier que le pod est Running
kubectl get pods

# Vérifier le port du conteneur
kubectl describe pod <pod-name> | grep Port

# Utiliser --address 0.0.0.0 pour accès externe
kubectl port-forward <pod-name> 8080:80 --address 0.0.0.0

# Vérifier le firewall
sudo ufw status
sudo ufw allow 8080/tcp
```

---

## 💪 Problèmes de Performance

### Problème : Pods lents à démarrer

**Causes :**
1. Images volumineuses
2. Ressources limitées
3. Lenteur réseau

**Solutions :**
```bash
# Utiliser imagePullPolicy: IfNotPresent
spec:
  containers:
  - name: app
    image: myapp:latest
    imagePullPolicy: IfNotPresent

# Pré-télécharger les images
docker pull <image>

# Augmenter les ressources
# Dans Vagrantfile:
v.memory = 8192
v.cpus = 6
```

---

### Problème : Cluster lent ou instable

**Diagnostic :**
```bash
kubectl top nodes
kubectl top pods -A
kubectl get events -A | grep -i error
```

**Solutions :**
```bash
# Nettoyer les pods terminés
kubectl delete pods --field-selector=status.phase=Succeeded --all-namespaces
kubectl delete pods --field-selector=status.phase=Failed --all-namespaces

# Nettoyer les images inutilisées
minikube ssh
docker system prune -a

# Augmenter les ressources système
# Dans /etc/sysctl.conf:
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
```

---

## 🔄 Procédures de Récupération

### Réinitialiser complètement Minikube

```bash
# Arrêter et supprimer
sudo minikube stop
sudo minikube delete --all --purge

# Nettoyer
sudo rm -rf ~/.minikube
sudo rm -rf /root/.minikube
sudo rm -rf /tmp/minikube*
sudo rm -rf /tmp/juju-*
sudo rm -rf /etc/kubernetes

# Redémarrer
sudo sysctl fs.protected_regular=0
sudo minikube start --driver=none --container-runtime=containerd --force
```

---

### Réinitialiser kubectl

```bash
# Sauvegarder
cp ~/.kube/config ~/.kube/config.backup

# Supprimer
rm -rf ~/.kube
rm -rf ~/.minikube

# Copier depuis root
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R $USER:$USER ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config
```

---

### Redémarrer les composants système

```bash
# Containerd
sudo systemctl restart containerd

# Kubelet
sudo systemctl restart kubelet

# Tous les pods système
kubectl delete pods -n kube-system --all

# Minikube
minikube stop
minikube start
```

---

## 📝 Checklist de Diagnostic

Lorsqu'un problème survient, suivez ces étapes :

1. **Identifier le composant défaillant**
   ```bash
   kubectl get all -A
   kubectl get events -A --sort-by=.metadata.creationTimestamp
   ```

2. **Vérifier les logs**
   ```bash
   kubectl logs <pod-name>
   sudo journalctl -xeu containerd
   sudo journalctl -xeu kubelet
   minikube logs
   ```

3. **Vérifier les ressources**
   ```bash
   kubectl top nodes
   kubectl top pods -A
   free -h
   df -h
   ```

4. **Vérifier la configuration**
   ```bash
   kubectl config view
   kubectl describe <resource> <name>
   ```

5. **Tester la connectivité**
   ```bash
   kubectl run test --image=busybox --rm -it --restart=Never -- ping google.com
   kubectl run test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
   ```

6. **Si nécessaire, redémarrer**
   ```bash
   sudo systemctl restart containerd
   sudo systemctl restart kubelet
   minikube stop && minikube start
   ```

---

## 🆘 Obtenir de l'Aide

### Logs et informations système
```bash
# Créer un rapport complet
minikube logs --file=minikube-logs.txt
kubectl cluster-info dump > cluster-dump.txt
kubectl get all -A -o yaml > all-resources.yaml

# Informations système
sudo journalctl --no-pager > system-logs.txt
```

### Ressources utiles
- Documentation Kubernetes: https://kubernetes.io/docs/
- Documentation Minikube: https://minikube.sigs.k8s.io/docs/
- GitHub Issues Minikube: https://github.com/kubernetes/minikube/issues
- Stack Overflow: https://stackoverflow.com/questions/tagged/kubernetes

---

**Note **: Ce guide couvre les problèmes les plus courants. Pour des problèmes spécifiques, consultez la documentation officielle ou les forums de la communauté.
