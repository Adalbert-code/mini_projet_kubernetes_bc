# Checklist de Debogage - TP-4 Avance

Checklist systematique pour diagnostiquer et resoudre les problemes du TP-4.

---

## Checklist Rapide

Utilisez cette checklist pour diagnostiquer rapidement un probleme:

```
[ ] 1. Minikube est-il demarre?
[ ] 2. Les addons (ingress, metallb) sont-ils actives?
[ ] 3. L'Ingress Controller est-il Running?
[ ] 4. Les namespaces existent-ils?
[ ] 5. Les pods sont-ils en Running?
[ ] 6. Les services existent-ils?
[ ] 7. Les Ingress sont-ils configures?
[ ] 8. Le fichier hosts est-il configure?
[ ] 9. Le bon NodePort est-il utilise?
```

---

## 1. Verification de l'Infrastructure

### Minikube

```bash
# [ ] Verifier le status de Minikube
minikube status
```

**Resultat attendu:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

**Si Stopped:**
```bash
sudo minikube start --driver=none --container-runtime=containerd --force
sudo cp -r /root/.kube ~/.kube
sudo chown -R vagrant:vagrant ~/.kube
sed -i "s|/root|$HOME|g" ~/.kube/config
```

### Noeud Kubernetes

```bash
# [ ] Verifier le noeud
kubectl get nodes
```

**Resultat attendu:**
```
NAME       STATUS   ROLES           AGE    VERSION
minikube   Ready    control-plane   XXd    v1.31.0
```

**Si NotReady:** Voir section Troubleshooting.

---

## 2. Verification des Addons

### Ingress Controller

```bash
# [ ] Verifier que l'addon ingress est active
minikube addons list | grep ingress
```

**Resultat attendu:**
```
| ingress    | minikube | enabled  |
```

**Si disabled:**
```bash
minikube addons enable ingress
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### MetalLB

```bash
# [ ] Verifier que MetalLB est active
minikube addons list | grep metallb
```

**Si disabled:**
```bash
minikube addons enable metallb
```

---

## 3. Verification de l'Ingress Controller

```bash
# [ ] Pods de l'Ingress Controller
kubectl get pods -n ingress-nginx
```

**Resultat attendu:**
```
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-XXXXX              1/1     Running   0          XXm
```

```bash
# [ ] Service de l'Ingress Controller
kubectl get svc -n ingress-nginx
```

**Resultat attendu:**
```
NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
ingress-nginx-controller   NodePort   10.x.x.x        <none>        80:32XXX/TCP,443:32XXX/TCP
```

**Noter le NodePort HTTP (ex: 32655)**

---

## 4. Verification des Namespaces

```bash
# [ ] Verifier les namespaces du TP-4
kubectl get namespaces | grep -E "bd|voting|odoo"
```

**Resultat attendu:**
```
bd              Active   XXm
odoo            Active   XXm
voting          Active   XXm
```

**Si manquant:**
```bash
cd /vagrant/tp-4
kubectl apply -f postgresql/namespace.yaml
kubectl apply -f voting-app/namespace.yaml
kubectl apply -f odoo/namespace.yaml
```

---

## 5. Verification des Pods

### Namespace bd

```bash
# [ ] Pods PostgreSQL + PgAdmin
kubectl get pods -n bd
```

**Resultat attendu:**
```
NAME                        READY   STATUS    RESTARTS   AGE
pgadmin-XXXXX               1/1     Running   0          XXm
postgres-XXXXX              1/1     Running   0          XXm
```

### Namespace voting

```bash
# [ ] Pods Voting App
kubectl get pods -n voting
```

**Resultat attendu:**
```
NAME                       READY   STATUS    RESTARTS   AGE
db-XXXXX                   1/1     Running   0          XXm
redis-XXXXX                1/1     Running   0          XXm
result-XXXXX               1/1     Running   0          XXm
vote-XXXXX                 1/1     Running   0          XXm
vote-XXXXX                 1/1     Running   0          XXm
worker-XXXXX               1/1     Running   0          XXm
```

### Namespace odoo

```bash
# [ ] Pods Odoo
kubectl get pods -n odoo
```

**Resultat attendu:**
```
NAME                              READY   STATUS    RESTARTS   AGE
odoo-XXXXX                        1/1     Running   0          XXm
odoo-postgres-XXXXX               1/1     Running   0          XXm
```

### Si un pod n'est pas Running

```bash
# Voir les details et events
kubectl describe pod <nom-du-pod> -n <namespace>

# Voir les logs
kubectl logs <nom-du-pod> -n <namespace>

# Si CrashLoopBackOff, voir logs du crash precedent
kubectl logs <nom-du-pod> -n <namespace> --previous
```

---

## 6. Verification des Services

### Namespace bd

```bash
# [ ] Services PostgreSQL + PgAdmin
kubectl get svc -n bd
```

**Resultat attendu:**
```
NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
pgadmin    ClusterIP   10.x.x.x        <none>        80/TCP
postgres   ClusterIP   10.x.x.x        <none>        5432/TCP
```

### Namespace voting

```bash
# [ ] Services Voting App
kubectl get svc -n voting
```

**Resultat attendu:**
```
NAME     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
db       ClusterIP   10.x.x.x        <none>        5432/TCP
redis    ClusterIP   10.x.x.x        <none>        6379/TCP
result   ClusterIP   10.x.x.x        <none>        80/TCP
vote     ClusterIP   10.x.x.x        <none>        80/TCP
```

### Namespace odoo

```bash
# [ ] Services Odoo
kubectl get svc -n odoo
```

**Resultat attendu:**
```
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
odoo            ClusterIP   10.x.x.x        <none>        8069/TCP
odoo-postgres   ClusterIP   10.x.x.x        <none>        5432/TCP
```

### Verifier les endpoints

```bash
# [ ] Endpoints doivent pointer vers des IPs de pods
kubectl get endpoints -n voting
kubectl get endpoints -n bd
kubectl get endpoints -n odoo
```

**Si endpoints vides:** Les selectors du service ne matchent pas les labels des pods.

---

## 7. Verification des Ingress

```bash
# [ ] Tous les Ingress
kubectl get ingress --all-namespaces
```

**Resultat attendu:**
```
NAMESPACE   NAME                 CLASS   HOSTS                       ADDRESS         PORTS   AGE
bd          pgadmin-ingress      nginx   pgadmin.local               192.168.49.2    80      XXm
odoo        odoo-ingress         nginx   odoo.local                  192.168.49.2    80      XXm
voting      voting-app-ingress   nginx   vote.local,result.local     192.168.49.2    80      XXm
```

### Verifier les details d'un Ingress

```bash
# [ ] Description de l'Ingress
kubectl describe ingress voting-app-ingress -n voting
```

**Verifier:**
- Le backend pointe vers le bon service
- Le port est correct
- Pas d'erreurs dans les events

---

## 8. Verification de l'Acces

### Depuis la VM

```bash
# [ ] Obtenir le NodePort
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODEPORT"

# [ ] Tester chaque application
curl -s -H "Host: vote.local" http://localhost:$NODEPORT | head -20
curl -s -H "Host: result.local" http://localhost:$NODEPORT | head -20
curl -s -H "Host: pgadmin.local" http://localhost:$NODEPORT | head -20
curl -s -H "Host: odoo.local" http://localhost:$NODEPORT | head -20
```

### Depuis Windows

```bash
# [ ] Verifier l'IP de la VM
ip addr show eth1 | grep inet
# IP attendue: 192.168.56.10
```

```powershell
# [ ] Verifier le fichier hosts Windows
type C:\Windows\System32\drivers\etc\hosts
# Doit contenir:
# 192.168.56.10 pgadmin.local vote.local result.local odoo.local
```

```powershell
# [ ] Tester avec curl (PowerShell)
curl http://vote.local:32655
curl http://result.local:32655
```

---

## 9. Diagnostic par Application

### Vote ne fonctionne pas

```bash
# [ ] Verifier le pod vote
kubectl get pods -n voting -l app=vote
kubectl logs deployment/vote -n voting

# [ ] Verifier la connexion a Redis
kubectl exec deployment/vote -n voting -- env | grep REDIS

# [ ] Verifier que Redis est accessible
kubectl run test --rm -it --image=redis -n voting -- redis-cli -h redis ping
```

### Result ne fonctionne pas

```bash
# [ ] Verifier le pod result
kubectl get pods -n voting -l app=result
kubectl logs deployment/result -n voting

# [ ] Verifier la connexion a la DB
kubectl exec deployment/result -n voting -- env | grep DB
```

### PgAdmin ne fonctionne pas

```bash
# [ ] Verifier le pod pgadmin
kubectl get pods -n bd -l app=pgadmin
kubectl logs deployment/pgadmin -n bd

# [ ] Verifier que PostgreSQL est accessible
kubectl exec deployment/pgadmin -n bd -- nc -zv postgres 5432
```

### Odoo ne fonctionne pas

```bash
# [ ] Verifier le pod Odoo
kubectl get pods -n odoo -l app=odoo
kubectl logs deployment/odoo -n odoo

# [ ] Odoo peut prendre du temps a demarrer (image ~1GB)
# Verifier si l'image est telechargee
kubectl describe pod -n odoo -l app=odoo | grep -A5 "Events:"

# [ ] Verifier la connexion PostgreSQL
kubectl exec deployment/odoo -n odoo -- env | grep POSTGRES
```

---

## 10. Verification Globale Rapide

Script de verification complete:

```bash
#!/bin/bash
echo "=== Verification TP-4 ==="

echo -e "\n--- Minikube ---"
minikube status | head -5

echo -e "\n--- Nodes ---"
kubectl get nodes

echo -e "\n--- Namespaces ---"
kubectl get ns | grep -E "bd|voting|odoo"

echo -e "\n--- Pods ---"
kubectl get pods -A | grep -E "bd|voting|odoo|ingress-nginx"

echo -e "\n--- Services ---"
kubectl get svc -A | grep -E "bd|voting|odoo"

echo -e "\n--- Ingress ---"
kubectl get ingress -A

echo -e "\n--- Tests curl ---"
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -n "$NODEPORT" ]; then
    echo "NodePort: $NODEPORT"
    for host in vote.local result.local pgadmin.local odoo.local; do
        if curl -s -H "Host: $host" http://localhost:$NODEPORT -o /dev/null -w "%{http_code}" | grep -q "200\|302"; then
            echo "  $host: OK"
        else
            echo "  $host: ERREUR"
        fi
    done
fi
```

---

## Resume des Etats de Pods

| Status | Signification | Action |
|--------|---------------|--------|
| Running | Pod fonctionne | OK |
| Pending | En attente de ressources | Verifier describe |
| ContainerCreating | Image en telechargement | Attendre |
| ImagePullBackOff | Echec telechargement image | Verifier nom image |
| CrashLoopBackOff | Pod crash en boucle | Voir logs |
| Error | Erreur de demarrage | Voir logs |
| Terminating | En cours de suppression | Attendre ou forcer |

---

## Auteur

Adalbert NANDA - Janvier 2026
