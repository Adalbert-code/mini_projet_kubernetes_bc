# Troubleshooting - TP-4 Avance

Solutions detaillees pour les problemes courants du TP-4.

---

## Table des matieres

1. [Problemes Minikube](#1-problemes-minikube)
2. [Problemes Ingress Controller](#2-problemes-ingress-controller)
3. [Problemes de Pods](#3-problemes-de-pods)
4. [Problemes de Services](#4-problemes-de-services)
5. [Problemes d'Ingress](#5-problemes-dingress)
6. [Problemes d'Acces depuis Windows](#6-problemes-dacces-depuis-windows)
7. [Problemes specifiques aux Applications](#7-problemes-specifiques-aux-applications)
8. [Problemes de Persistance](#8-problemes-de-persistance)

---

## 1. Problemes Minikube

### Erreur: "The connection to the server localhost:8443 was refused"

**Cause:** Minikube n'est pas demarre ou kubectl n'est pas configure.

**Solution:**
```bash
# Demarrer Minikube
sudo minikube start --driver=none --container-runtime=containerd --force

# Reconfigurer kubectl
sudo cp -r /root/.kube ~/.kube
sudo cp -r /root/.minikube ~/.minikube
sudo chown -R vagrant:vagrant ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config

# Verifier
kubectl get nodes
```

### Erreur: "minikube does not have a driver configured"

**Cause:** Driver non specifie.

**Solution:**
```bash
sudo minikube start --driver=none --container-runtime=containerd --force
```

### Erreur: "Exiting due to GUEST_MISSING_CONNTRACK"

**Cause:** Package conntrack manquant.

**Solution:**
```bash
sudo apt-get update
sudo apt-get install -y conntrack
sudo minikube start --driver=none --container-runtime=containerd --force
```

### Minikube demarre mais node est NotReady

**Cause:** Probleme avec containerd ou kubelet.

**Solution:**
```bash
# Verifier containerd
sudo systemctl status containerd

# Redemarrer si necessaire
sudo systemctl restart containerd

# Redemarrer Minikube
sudo minikube stop
sudo minikube start --driver=none --container-runtime=containerd --force
```

### Reset complet de Minikube

Si rien ne fonctionne:
```bash
# Supprimer completement
sudo minikube delete --all --purge
sudo rm -rf ~/.minikube /root/.minikube
sudo rm -rf ~/.kube /root/.kube
sudo rm -rf /tmp/minikube* /tmp/juju-*

# Reinstaller proprement
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
```

---

## 2. Problemes Ingress Controller

### Erreur: "failed calling webhook 'validate.nginx.ingress.kubernetes.io'"

**Cause:** L'Ingress Controller n'est pas encore pret.

**Solution:**
```bash
# Attendre que le controller soit pret
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Si timeout, verifier les pods
kubectl get pods -n ingress-nginx

# Reessayer l'apply des Ingress
kubectl apply -f ingress/
```

### Ingress Controller en CrashLoopBackOff

**Cause:** Conflit de ports ou ressources insuffisantes.

**Solution:**
```bash
# Voir les logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Supprimer et reactiver l'addon
minikube addons disable ingress
sleep 10
minikube addons enable ingress

# Attendre
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Pas de NodePort pour l'Ingress Controller

**Cause:** Service pas correctement configure.

**Solution:**
```bash
# Verifier le service
kubectl get svc -n ingress-nginx

# Si pas de NodePort visible, patcher le service
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  -p '{"spec": {"type": "NodePort"}}'
```

---

## 3. Problemes de Pods

### Pod en status Pending

**Causes possibles:**
- Pas assez de ressources
- PVC non lie
- Node selector non satisfait

**Diagnostic:**
```bash
kubectl describe pod <nom-pod> -n <namespace>
# Regarder la section "Events" en bas
```

**Solutions:**
```bash
# Si probleme de ressources
kubectl top nodes
kubectl describe node minikube | grep -A10 "Allocated resources"

# Si probleme de PVC
kubectl get pvc -n <namespace>
kubectl get pv
```

### Pod en ImagePullBackOff

**Cause:** Image Docker introuvable ou erreur de nom.

**Diagnostic:**
```bash
kubectl describe pod <nom-pod> -n <namespace> | grep -A5 "Events"
```

**Solutions:**
```bash
# Verifier le nom de l'image
kubectl get pod <nom-pod> -n <namespace> -o yaml | grep image:

# Tester le pull manuellement
sudo crictl pull <image-name>

# Si image privee, creer un secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<password> \
  -n <namespace>
```

### Pod en CrashLoopBackOff

**Cause:** L'application dans le conteneur crash au demarrage.

**Diagnostic:**
```bash
# Voir les logs actuels
kubectl logs <nom-pod> -n <namespace>

# Voir les logs du crash precedent
kubectl logs <nom-pod> -n <namespace> --previous

# Voir les events
kubectl describe pod <nom-pod> -n <namespace> | tail -30
```

**Solutions courantes:**
```bash
# Si probleme de variable d'environnement
kubectl get pod <nom-pod> -n <namespace> -o yaml | grep -A20 "env:"

# Si probleme de connexion a une DB
# Verifier que le service DB est accessible
kubectl run test --rm -it --image=busybox -n <namespace> -- nc -zv <service> <port>
```

### Pod bloque en Terminating

**Solution:**
```bash
# Forcer la suppression
kubectl delete pod <nom-pod> -n <namespace> --force --grace-period=0

# Si toujours bloque, supprimer les finalizers
kubectl patch pod <nom-pod> -n <namespace> -p '{"metadata":{"finalizers":null}}'
```

---

## 4. Problemes de Services

### Service sans Endpoints

**Cause:** Les selectors ne matchent pas les labels des pods.

**Diagnostic:**
```bash
# Voir les endpoints
kubectl get endpoints <service> -n <namespace>

# Voir les labels du service
kubectl get svc <service> -n <namespace> -o yaml | grep -A5 selector

# Voir les labels des pods
kubectl get pods -n <namespace> --show-labels
```

**Solution:**
Corriger les labels dans le deployment ou les selectors dans le service.

### Service ne repond pas

**Diagnostic:**
```bash
# Tester depuis un pod dans le meme namespace
kubectl run test --rm -it --image=busybox -n <namespace> -- wget -qO- http://<service>:<port>

# Tester la resolution DNS
kubectl run test --rm -it --image=busybox -n <namespace> -- nslookup <service>
```

### Connexion refusee entre services de namespaces differents

**Solution:** Utiliser le FQDN:
```bash
# Format: <service>.<namespace>.svc.cluster.local
# Exemple:
kubectl run test --rm -it --image=busybox -n voting -- wget -qO- http://postgres.bd.svc.cluster.local:5432
```

---

## 5. Problemes d'Ingress

### Erreur 503 Service Temporarily Unavailable

**Causes:**
- Le service backend n'existe pas
- Le service n'a pas d'endpoints
- Le port est incorrect

**Diagnostic:**
```bash
# Verifier l'Ingress
kubectl describe ingress <nom-ingress> -n <namespace>

# Verifier le service backend
kubectl get svc <service> -n <namespace>
kubectl get endpoints <service> -n <namespace>

# Verifier que le pod repond
kubectl port-forward svc/<service> 8080:<port> -n <namespace>
# Puis tester: curl http://localhost:8080
```

### Erreur 404 Not Found

**Cause:** Le path ne correspond a aucune regle.

**Solution:**
```bash
# Verifier les regles de l'Ingress
kubectl get ingress <nom-ingress> -n <namespace> -o yaml

# S'assurer que le path est correct (/ vs /app)
```

### Ingress sans ADDRESS

**Cause:** L'Ingress Controller n'a pas encore traite l'Ingress.

**Solution:**
```bash
# Verifier que l'Ingress Controller fonctionne
kubectl get pods -n ingress-nginx

# Verifier les logs de l'Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Verifier la classe d'Ingress
kubectl get ingress <nom-ingress> -n <namespace> -o yaml | grep ingressClassName
# Doit etre: nginx
```

### Host non reconnu

**Cause:** Le header Host ne correspond pas.

**Solution:**
```bash
# Verifier les hosts configures
kubectl get ingress -A -o wide

# Tester avec le bon header
curl -H "Host: vote.local" http://localhost:<nodeport>
```

---

## 6. Problemes d'Acces depuis Windows

### Impossible d'acceder aux URLs depuis le navigateur

**Checklist:**
```powershell
# 1. Verifier le fichier hosts
type C:\Windows\System32\drivers\etc\hosts

# 2. Verifier la connectivite a la VM
ping 192.168.56.10

# 3. Verifier le port
# Depuis la VM:
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### Erreur "ERR_CONNECTION_REFUSED" dans le navigateur

**Causes:**
- Mauvais port
- VM non accessible
- Firewall

**Solutions:**
```bash
# Dans la VM - verifier le NodePort
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}'

# Verifier que l'IP de la VM est correcte
ip addr show eth1 | grep inet

# Tester depuis la VM
curl -H "Host: vote.local" http://localhost:32655
```

### Fichier hosts ne fonctionne pas

**Solution:**
```powershell
# Ouvrir PowerShell en Administrateur
# Verifier que le fichier n'a pas d'extension cachee
dir C:\Windows\System32\drivers\etc\

# Editer avec notepad en admin
notepad C:\Windows\System32\drivers\etc\hosts

# S'assurer pas d'espace avant l'IP:
192.168.56.10 pgadmin.local vote.local result.local odoo.local

# Vider le cache DNS
ipconfig /flushdns
```

### Timeout lors de l'acces

**Causes:**
- VM eteinte
- Minikube arrete
- Firewall bloque

**Solutions:**
```bash
# Verifier que la VM est demarree
vagrant status

# Se connecter et verifier Minikube
vagrant ssh
minikube status

# Verifier le firewall (dans la VM)
sudo iptables -L -n | grep 32655
```

---

## 7. Problemes specifiques aux Applications

### Voting App - Vote ne s'affiche pas

**Diagnostic:**
```bash
kubectl logs deployment/vote -n voting
kubectl describe pod -n voting -l app=vote
```

**Solution:**
```bash
# Verifier la connexion a Redis
kubectl exec deployment/vote -n voting -- env | grep REDIS
kubectl run test --rm -it --image=redis -n voting -- redis-cli -h redis ping
```

### Voting App - Result affiche 0% / 0%

**Cause:** Le Worker n'a pas traite les votes.

**Diagnostic:**
```bash
kubectl logs deployment/worker -n voting
```

**Solution:**
```bash
# Verifier que le Worker peut se connecter a Redis et DB
kubectl exec deployment/worker -n voting -- env
kubectl logs deployment/worker -n voting -f
```

### PgAdmin - Erreur de connexion a PostgreSQL

**Configuration correcte dans PgAdmin:**
- Host: `postgres` (nom du service)
- Port: `5432`
- Username: `postgres`
- Password: `postgres123`

**Ou utiliser le FQDN:**
- Host: `postgres.bd.svc.cluster.local`

### Odoo - Page blanche ou erreur 500

**Cause:** Odoo est encore en train de s'initialiser (peut prendre plusieurs minutes).

**Diagnostic:**
```bash
kubectl logs deployment/odoo -n odoo -f
```

**Solution:**
Attendre que l'initialisation soit complete. Premiere connexion peut prendre 2-3 minutes.

### Odoo - ImagePullBackOff

**Cause:** Image Odoo (~1GB) est longue a telecharger.

**Solution:**
```bash
# Verifier la progression
kubectl describe pod -n odoo -l app=odoo | grep -A5 "Events"

# Attendre le telechargement
watch kubectl get pods -n odoo
```

---

## 8. Problemes de Persistance

### PersistentVolumeClaim en Pending

**Cause:** Pas de PV disponible ou StorageClass incorrect.

**Diagnostic:**
```bash
kubectl get pvc -n <namespace>
kubectl get pv
kubectl describe pvc <pvc-name> -n <namespace>
```

**Solution:**
```bash
# Creer le PV s'il n'existe pas
kubectl apply -f postgresql/postgres-pv.yaml

# Verifier le binding
kubectl get pv,pvc -A
```

### Donnees perdues apres redemarrage

**Cause:** PV/PVC non configure ou hostPath supprime.

**Solution:**
```bash
# Verifier que le PV utilise un chemin persistant
kubectl get pv -o yaml | grep hostPath

# S'assurer que le repertoire existe sur le noeud
ls -la /data/postgres
```

### PV bloque en "Released"

**Cause:** Le PVC a ete supprime mais le PV garde les donnees.

**Solution:**
```bash
# Supprimer le PV et le recreer
kubectl delete pv <pv-name>
kubectl apply -f <pv-file>.yaml
```

---

## Commandes de Diagnostic Rapide

```bash
# Etat global
kubectl get all,ingress,pv,pvc -A | grep -E "bd|voting|odoo|ingress-nginx"

# Events recents
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# Logs Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50

# Test rapide des apps
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')
for h in vote.local result.local pgadmin.local odoo.local; do
  echo -n "$h: "
  curl -s -o /dev/null -w "%{http_code}\n" -H "Host: $h" http://localhost:$NODEPORT
done
```

---

## Auteur

Adalbert NANDA - Janvier 2026
