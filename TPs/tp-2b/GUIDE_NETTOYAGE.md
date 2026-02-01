# 🧹 Guide de Nettoyage - VM Kubernetes TP-2

Guide complet pour nettoyer les ressources Kubernetes et la VM après le TP-2.

---

## 📋 Table des matières

1. [Nettoyage Rapide (Script automatique)](#nettoyage-rapide-script-automatique)
2. [Nettoyage Manuel (Commandes détaillées)](#nettoyage-manuel-commandes-détaillées)
3. [Vérification du Nettoyage](#vérification-du-nettoyage)
4. [Nettoyage Complet (Reset total)](#nettoyage-complet-reset-total)
5. [Gestion de la VM Vagrant](#gestion-de-la-vm-vagrant)

---

## 🚀 Nettoyage Rapide (Script automatique)

### Dans la VM

```bash
# 1. Se connecter à la VM
vagrant ssh

# 2. Aller dans le répertoire partagé
cd /vagrant/tp-2b

# 3. Exécuter le script de nettoyage
chmod +x cleanup.sh
./cleanup.sh
```

Le script fait automatiquement :
- ✅ Suppression de tous les pods
- ✅ Suppression de tous les deployments
- ✅ Suppression de tous les services (sauf kubernetes)
- ✅ Suppression de tous les replicasets
- ✅ Vérification qu'il ne reste rien
- ✅ Arrêt de Minikube

---

## 🔧 Nettoyage Manuel (Commandes détaillées)

### 1. Lister les ressources existantes

```bash
# Voir tout ce qui tourne
kubectl get all -n default

# Voir uniquement les pods
kubectl get pods

# Voir uniquement les deployments
kubectl get deployments

# Voir les services
kubectl get services

# Voir les replicasets
kubectl get replicasets
```

### 2. Supprimer les ressources du TP-2

#### Supprimer le pod simple-webapp-color

```bash
# Méthode 1 : Par nom
kubectl delete pod simple-webapp-color

# Méthode 2 : Par fichier
kubectl delete -f pod.yml

# Vérifier
kubectl get pods
```

#### Supprimer le deployment nginx

```bash
# Méthode 1 : Par nom
kubectl delete deployment nginx-deployment

# Méthode 2 : Par fichier
kubectl delete -f nginx-deployment.yml

# Vérifier
kubectl get deployments
kubectl get pods  # Les pods du deployment seront aussi supprimés
kubectl get replicasets  # Les RS seront aussi supprimés
```

### 3. Supprimer TOUTES les ressources du namespace default

```bash
# Attention : cette commande supprime TOUT dans le namespace default
kubectl delete pods --all -n default
kubectl delete deployments --all -n default
kubectl delete services --all -n default  # Sauf le service "kubernetes"
kubectl delete replicasets --all -n default

# Ou en une seule commande
kubectl delete all --all -n default
```

### 4. Arrêter Minikube

```bash
# Arrêt propre
minikube stop

# Vérifier le statut
minikube status
```

---

## ✅ Vérification du Nettoyage

### Vérifier qu'il ne reste aucune ressource

```bash
# Voir toutes les ressources
kubectl get all -n default

# Résultat attendu : seulement le service "kubernetes"
# NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   XXm

# Vérifier les pods
kubectl get pods
# Résultat attendu : No resources found in default namespace.

# Vérifier les deployments
kubectl get deployments
# Résultat attendu : No resources found in default namespace.

# Vérifier les replicasets
kubectl get rs
# Résultat attendu : No resources found in default namespace.
```

### Vérifier l'état de Minikube

```bash
minikube status

# Résultat attendu si arrêté :
# minikube
# type: Control Plane
# host: Stopped
# kubelet: Stopped
# apiserver: Stopped
# kubeconfig: Stopped
```

---

## 🔥 Nettoyage Complet (Reset total)

Si tu veux tout supprimer et repartir de zéro :

### Option 1 : Supprimer uniquement Minikube

```bash
# Dans la VM
sudo minikube delete --all --purge

# Nettoyer les fichiers temporaires
sudo rm -rf ~/.minikube
sudo rm -rf /root/.minikube
sudo rm -rf /tmp/minikube*
sudo rm -rf /tmp/juju-*

# Vérifier
minikube status
# Résultat : Profile "minikube" not found
```

### Option 2 : Supprimer Minikube + configurations

```bash
# Tout supprimer
sudo minikube delete --all --purge
sudo rm -rf ~/.minikube /root/.minikube
sudo rm -rf ~/.kube /root/.kube
sudo rm -rf /tmp/minikube* /tmp/juju-*
sudo rm -rf /etc/kubernetes

# Redémarrer pour un environnement propre
sudo minikube start \
    --driver=none \
    --kubernetes-version=v1.31.0 \
    --container-runtime=containerd \
    --force

# Reconfigurer les permissions
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R vagrant:vagrant ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config
```

---

## 💻 Gestion de la VM Vagrant

### Arrêter la VM (depuis ta machine hôte)

```bash
# Aller dans le répertoire du projet
cd C:\Users\adaln\EAZYTRAINING\DevOpsBootCamps\kubernetes\kubernetes-training\tp-2b

# Arrêter la VM proprement
vagrant halt

# Vérifier le statut
vagrant status
```

### Redémarrer la VM

```bash
# Depuis le répertoire du projet
vagrant up

# Se connecter
vagrant ssh
```

### Supprimer complètement la VM

```bash
# Attention : supprime TOUTE la VM
vagrant destroy -f

# Pour recréer une VM propre
vagrant up
```

### Sauvegarder l'état de la VM

```bash
# Sauvegarder l'état actuel (suspend)
vagrant suspend

# Reprendre
vagrant resume
```

---

## 📊 États de la VM et leurs commandes

| État souhaité | Commande | Description |
|---------------|----------|-------------|
| Arrêter proprement | `vagrant halt` | Éteint la VM, disque préservé |
| Suspendre | `vagrant suspend` | Met en pause, RAM sauvegardée |
| Supprimer | `vagrant destroy -f` | Supprime complètement la VM |
| Redémarrer | `vagrant reload` | Équivalent à halt + up |
| Reprovisioner | `vagrant provision` | Réexécute le script d'installation |
| État complet | `vagrant up` | Démarre ou crée la VM |

---

## 🔄 Scénarios Courants

### Scénario 1 : Je veux juste nettoyer les pods/deployments du TP

```bash
# Dans la VM
vagrant ssh
cd /vagrant/tp-2b
./cleanup.sh
exit

# La VM reste démarrée, Minikube arrêté
```

### Scénario 2 : Je veux arrêter la VM pour économiser des ressources

```bash
# Sur ta machine Windows
cd C:\Users\adaln\EAZYTRAINING\DevOpsBootCamps\kubernetes\kubernetes-training\tp-2b
vagrant halt
```

### Scénario 3 : Je veux tout recommencer à zéro

```bash
# Sur ta machine Windows - Supprimer la VM
vagrant destroy -f

# Recréer une VM propre
vagrant up

# Se connecter
vagrant ssh

# Vérifier que tout fonctionne
kubectl get nodes
```

### Scénario 4 : Minikube est cassé, je veux le réinstaller

```bash
# Dans la VM
sudo minikube delete --all --purge
sudo rm -rf ~/.minikube /root/.minikube /tmp/minikube*

# Redémarrer Minikube
sudo minikube start \
    --driver=none \
    --kubernetes-version=v1.31.0 \
    --container-runtime=containerd \
    --force

# Reconfigurer
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R vagrant:vagrant ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config

# Vérifier
kubectl get nodes
```

---

## 🧪 Vérifications Post-Nettoyage

### Checklist complète

```bash
# 1. Pas de pods en cours
kubectl get pods
# Attendu: No resources found

# 2. Pas de deployments
kubectl get deployments
# Attendu: No resources found

# 3. Pas de replicasets
kubectl get rs
# Attendu: No resources found

# 4. Seulement le service kubernetes
kubectl get services
# Attendu: Seulement "kubernetes"

# 5. Pas de namespaces custom (si applicable)
kubectl get namespaces
# Attendu: default, kube-system, kube-public, kube-node-lease

# 6. Cluster sain (si Minikube tourne)
kubectl cluster-info
kubectl get nodes

# 7. Ressources système OK
kubectl get pods -n kube-system
# Attendu: Tous les pods système en Running
```

---

## ⚠️ Erreurs Courantes et Solutions

### Erreur : "pod is being deleted but stuck"

```bash
# Forcer la suppression
kubectl delete pod <pod-name> --force --grace-period=0

# Si vraiment bloqué
kubectl delete pod <pod-name> --force --grace-period=0 --namespace default
```

### Erreur : "connection refused" après cleanup

```bash
# Minikube probablement arrêté, le redémarrer
sudo minikube start --driver=none --container-runtime=containerd --force
sudo chown -R vagrant:vagrant ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config
```

### Erreur : "namespace stuck in Terminating"

```bash
# Si un namespace ne se supprime pas
kubectl get namespace <namespace-name> -o json > tmp.json
# Éditer tmp.json et retirer "finalizers": [...]
kubectl replace --raw "/api/v1/namespaces/<namespace-name>/finalize" -f ./tmp.json
```

---

## 📝 Résumé des Commandes Essentielles

```bash
# NETTOYAGE RAPIDE
kubectl delete all --all -n default
minikube stop

# VÉRIFICATION
kubectl get all -n default
minikube status

# RESET COMPLET MINIKUBE
sudo minikube delete --all --purge

# RESET COMPLET VM (depuis Windows)
vagrant destroy -f && vagrant up

# REDÉMARRAGE MINIKUBE
sudo minikube start --driver=none --container-runtime=containerd --force
sudo cp -r /root/.kube ~/.kube
sudo chown -R vagrant:vagrant ~/.kube
sed -i "s|/root|$HOME|g" ~/.kube/config
```

---

## 💡 Bonnes Pratiques

1. **Toujours vérifier** avant de tout supprimer
   ```bash
   kubectl get all -A
   ```

2. **Utiliser des labels** pour supprimer sélectivement
   ```bash
   kubectl delete pods -l app=nginx
   ```

3. **Faire des sauvegardes** avant gros nettoyage
   ```bash
   kubectl get all -o yaml > backup.yaml
   ```

4. **Arrêter Minikube** quand tu ne l'utilises pas (économise ressources)
   ```bash
   minikube stop
   ```

5. **Documenter** tes expérimentations pour pouvoir les reproduire

---

**Nettoyage terminé !** 🎉

Ta VM est maintenant propre et prête pour le prochain TP ou pour être arrêtée.
