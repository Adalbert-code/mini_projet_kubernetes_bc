# 🚀 Guide des Commandes Kubernetes Essentielles

Référence rapide des commandes Kubernetes les plus utilisées.

---

## 📑 Table des matières

1. [Commandes de Base](#commandes-de-base)
2. [Pods](#pods)
3. [Deployments](#deployments)
4. [Services](#services)
5. [ConfigMaps & Secrets](#configmaps--secrets)
6. [Namespaces](#namespaces)
7. [Volumes](#volumes)
8. [Networking](#networking)
9. [Troubleshooting](#troubleshooting)

---

## 🔰 Commandes de Base

### Informations du cluster
```bash
kubectl cluster-info
kubectl version
kubectl get nodes
kubectl get componentstatuses
kubectl get all -A
```

### Aide et documentation
```bash
kubectl --help
kubectl <command> --help
kubectl explain <resource>
kubectl explain pod.spec.containers
```

---

## 🐳 Pods

### Créer et gérer des pods
```bash
# Créer un pod depuis un fichier YAML
kubectl apply -f pod.yaml
kubectl create -f pod.yaml

# Créer un pod impérativement
kubectl run nginx --image=nginx
kubectl run nginx --image=nginx --port=80
kubectl run busybox --image=busybox --rm -it --restart=Never -- /bin/sh

# Lister les pods
kubectl get pods
kubectl get pods -A
kubectl get pods -o wide
kubectl get pods -n <namespace>
kubectl get pods --show-labels
kubectl get pods -l app=nginx

# Décrire un pod
kubectl describe pod <pod-name>

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Suivre en temps réel
kubectl logs <pod-name> --previous  # Logs du conteneur précédent
kubectl logs <pod-name> -c <container-name>  # Multi-conteneurs

# Exécuter des commandes
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- /bin/bash

# Port-forward
kubectl port-forward <pod-name> 8080:80
kubectl port-forward <pod-name> 8080:80 --address 0.0.0.0

# Copier des fichiers
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file

# Supprimer un pod
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --force --grace-period=0
kubectl delete pods --all
kubectl delete pods -l app=nginx
```

---

## 📦 Deployments

### Créer et gérer des deployments
```bash
# Créer un deployment
kubectl apply -f deployment.yaml
kubectl create deployment nginx --image=nginx
kubectl create deployment nginx --image=nginx --replicas=3

# Lister les deployments
kubectl get deployments
kubectl get deploy -o wide
kubectl get deploy -A

# Décrire un deployment
kubectl describe deployment <deployment-name>

# Scaler
kubectl scale deployment <deployment-name> --replicas=5

# Autoscaling
kubectl autoscale deployment <deployment-name> --min=2 --max=10 --cpu-percent=80

# Mettre à jour l'image
kubectl set image deployment/<deployment-name> <container-name>=<image>:<tag>
kubectl set image deployment/nginx-deployment nginx=nginx:1.21

# Rollout
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name> --to-revision=2
kubectl rollout restart deployment/<deployment-name>
kubectl rollout pause deployment/<deployment-name>
kubectl rollout resume deployment/<deployment-name>

# Éditer un deployment
kubectl edit deployment <deployment-name>

# Supprimer un deployment
kubectl delete deployment <deployment-name>
```

### ReplicaSets
```bash
kubectl get replicaset
kubectl get rs
kubectl describe rs <replicaset-name>
kubectl delete rs <replicaset-name>
```

---

## 🌐 Services

### Créer et gérer des services
```bash
# Créer un service
kubectl apply -f service.yaml
kubectl create service clusterip nginx --tcp=80:80
kubectl create service nodeport nginx --tcp=80:80 --node-port=30080
kubectl create service loadbalancer nginx --tcp=80:80

# Exposer un deployment
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl expose deployment nginx --port=80 --type=ClusterIP

# Lister les services
kubectl get services
kubectl get svc
kubectl get svc -A
kubectl get svc -o wide

# Décrire un service
kubectl describe service <service-name>

# Voir les endpoints
kubectl get endpoints
kubectl get ep <service-name>

# Port-forward vers un service
kubectl port-forward service/<service-name> 8080:80

# Supprimer un service
kubectl delete service <service-name>
```

---

## 🔐 ConfigMaps & Secrets

### ConfigMaps
```bash
# Créer un ConfigMap
kubectl create configmap <name> --from-literal=key1=value1 --from-literal=key2=value2
kubectl create configmap <name> --from-file=config.txt
kubectl create configmap <name> --from-file=configs/
kubectl apply -f configmap.yaml

# Lister
kubectl get configmaps
kubectl get cm

# Décrire
kubectl describe configmap <name>

# Voir le contenu
kubectl get configmap <name> -o yaml

# Supprimer
kubectl delete configmap <name>
```

### Secrets
```bash
# Créer un secret
kubectl create secret generic <name> --from-literal=password=secret123
kubectl create secret generic <name> --from-file=ssh-key=~/.ssh/id_rsa
kubectl apply -f secret.yaml

# Types de secrets
kubectl create secret docker-registry <name> --docker-server=<server> --docker-username=<user> --docker-password=<pwd>
kubectl create secret tls <name> --cert=path/to/cert --key=path/to/key

# Lister
kubectl get secrets

# Décrire
kubectl describe secret <name>

# Voir le contenu (base64)
kubectl get secret <name> -o yaml

# Décoder un secret
kubectl get secret <name> -o jsonpath='{.data.password}' | base64 --decode

# Supprimer
kubectl delete secret <name>
```

---

## 📂 Namespaces

```bash
# Lister les namespaces
kubectl get namespaces
kubectl get ns

# Créer un namespace
kubectl create namespace <name>

# Basculer de namespace (dans le contexte)
kubectl config set-context --current --namespace=<name>

# Opérer dans un namespace spécifique
kubectl get pods -n <namespace>
kubectl apply -f pod.yaml -n <namespace>

# Supprimer un namespace (⚠️ supprime tout dedans)
kubectl delete namespace <name>
```

---

## 💾 Volumes

### PersistentVolumes (PV)
```bash
kubectl get pv
kubectl describe pv <pv-name>
kubectl delete pv <pv-name>
```

### PersistentVolumeClaims (PVC)
```bash
kubectl get pvc
kubectl get pvc -A
kubectl describe pvc <pvc-name>
kubectl delete pvc <pvc-name>
```

### StorageClasses
```bash
kubectl get storageclass
kubectl get sc
kubectl describe sc <sc-name>
```

---

## 🔌 Networking

### Ingress
```bash
kubectl get ingress
kubectl get ing -A
kubectl describe ingress <ingress-name>
kubectl apply -f ingress.yaml
kubectl delete ingress <ingress-name>
```

### NetworkPolicies
```bash
kubectl get networkpolicies
kubectl get netpol
kubectl describe netpol <policy-name>
```

---

## 🛠️ Troubleshooting

### Événements
```bash
kubectl get events
kubectl get events -A
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector type=Warning
```

### Logs
```bash
# Logs de composants système
kubectl logs -n kube-system <pod-name>
kubectl logs -n kube-system -l k8s-app=kube-dns

# Logs de plusieurs pods
kubectl logs -l app=nginx --all-containers=true
```

### Monitoring
```bash
# Metrics (nécessite metrics-server)
kubectl top nodes
kubectl top pods
kubectl top pods -A
kubectl top pods --containers
```

### Debug
```bash
# Créer un pod de debug
kubectl run debug --image=busybox --rm -it --restart=Never -- /bin/sh
kubectl run debug --image=nicolaka/netshoot --rm -it --restart=Never -- /bin/bash

# Vérifier la connectivité
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl http://service-name
```

---

## 📝 Manifests et Génération

### Générer des manifests
```bash
# Dry-run pour générer YAML
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
kubectl create service clusterip nginx --tcp=80:80 --dry-run=client -o yaml > service.yaml

# Créer sans appliquer (validation)
kubectl apply -f manifest.yaml --dry-run=client
kubectl apply -f manifest.yaml --dry-run=server
```

### Éditer des ressources
```bash
# Éditer directement
kubectl edit pod <pod-name>
kubectl edit deployment <deployment-name>

# Patcher
kubectl patch deployment <name> -p '{"spec":{"replicas":5}}'
```

### Exporter des ressources
```bash
kubectl get pod <pod-name> -o yaml > pod.yaml
kubectl get deployment <deploy-name> -o yaml > deployment.yaml
kubectl get all -o yaml > all-resources.yaml
```

---

## 🎯 Labels et Selectors

```bash
# Ajouter un label
kubectl label pods <pod-name> environment=production
kubectl label pods <pod-name> tier=frontend

# Modifier un label
kubectl label pods <pod-name> environment=staging --overwrite

# Supprimer un label
kubectl label pods <pod-name> environment-

# Filtrer par label
kubectl get pods -l environment=production
kubectl get pods -l 'environment in (prod,staging)'
kubectl get pods -l environment=prod,tier=frontend

# Voir les labels
kubectl get pods --show-labels
```

---

## 🔄 Contextes et Configuration

```bash
# Voir la configuration
kubectl config view

# Voir les contextes
kubectl config get-contexts

# Changer de contexte
kubectl config use-context <context-name>

# Voir le contexte actuel
kubectl config current-context

# Définir un namespace par défaut
kubectl config set-context --current --namespace=<namespace>
```

---

## 💡 Astuces et Raccourcis

### Alias recommandés
```bash
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kga='kubectl get all -A'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kdel='kubectl delete'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
```

### Options communes
```bash
-A, --all-namespaces    # Tous les namespaces
-n, --namespace         # Namespace spécifique
-o, --output            # Format de sortie (yaml, json, wide, name)
-l, --selector          # Sélecteur de labels
-w, --watch             # Surveiller les changements
--dry-run=client        # Simuler sans créer
--force                 # Forcer l'opération
--grace-period=0        # Suppression immédiate
```

### Formats de sortie
```bash
-o yaml                 # YAML complet
-o json                 # JSON complet
-o wide                 # Informations supplémentaires
-o name                 # Nom uniquement
-o jsonpath='{...}'     # Extraction spécifique
```

### Completion bash/zsh
```bash
# Bash
source <(kubectl completion bash)
complete -F __start_kubectl k

# Zsh
source <(kubectl completion zsh)
```

---

## 🔍 JSONPath Exemples

```bash
# Extraire les noms de pods
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Extraire les images
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'

# IP des nodes
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# Statut des pods
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

---

## 📊 Commandes Avancées

### Apply vs Create
```bash
# Create (échoue si existe déjà)
kubectl create -f manifest.yaml

# Apply (crée ou met à jour)
kubectl apply -f manifest.yaml

# Replace (remplace complètement)
kubectl replace -f manifest.yaml --force
```

### Diff avant Apply
```bash
kubectl diff -f manifest.yaml
```

### Ressources multiples
```bash
# Appliquer plusieurs fichiers
kubectl apply -f file1.yaml -f file2.yaml

# Appliquer un répertoire
kubectl apply -f ./configs/

# Appliquer récursivement
kubectl apply -R -f ./configs/
```

---

**Note**: Cette liste n'est pas exhaustive. Utilisez `kubectl --help` et `kubectl <command> --help` pour plus de détails.
