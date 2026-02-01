# TP-4 Avancé : MetalLB, Ingress et Applications Multi-tiers

## Architecture Globale

```
                              ┌──────────────────────────────────────────────────────┐
                              │                    INGRESS CONTROLLER                 │
                              │                  (nginx-ingress)                      │
                              └────────────────────────┬─────────────────────────────┘
                                                       │
           ┌───────────────────────────────────────────┼───────────────────────────────────────────┐
           │                                           │                                           │
           ▼                                           ▼                                           ▼
    ┌──────────────┐                          ┌──────────────┐                          ┌──────────────┐
    │  pgadmin.local │                          │  vote.local  │                          │  odoo.local  │
    │  result.local  │                          │              │                          │              │
    └──────┬───────┘                          └──────┬───────┘                          └──────┬───────┘
           │                                         │                                         │
    ┌──────┴───────┐                          ┌──────┴───────┐                          ┌──────┴───────┐
    │ Namespace:bd │                          │Namespace:    │                          │Namespace:    │
    │              │                          │   voting     │                          │    odoo      │
    │ ┌──────────┐ │                          │              │                          │              │
    │ │PostgreSQL│ │                          │ ┌──────────┐ │                          │ ┌──────────┐ │
    │ │   :5432  │ │                          │ │  Redis   │ │                          │ │PostgreSQL│ │
    │ └──────────┘ │                          │ │  :6379   │ │                          │ │  :5432   │ │
    │              │                          │ └──────────┘ │                          │ └──────────┘ │
    │ ┌──────────┐ │                          │ ┌──────────┐ │                          │ ┌──────────┐ │
    │ │ PgAdmin  │ │                          │ │   Vote   │ │                          │ │   Odoo   │ │
    │ │   :80    │ │                          │ │   :80    │ │                          │ │  :8069   │ │
    │ └──────────┘ │                          │ └──────────┘ │                          │ └──────────┘ │
    │              │                          │ ┌──────────┐ │                          │              │
    │              │                          │ │  Result  │ │                          │              │
    │              │                          │ │   :80    │ │                          │              │
    │              │                          │ └──────────┘ │                          │              │
    │              │                          │ ┌──────────┐ │                          │              │
    │              │                          │ │  Worker  │ │                          │              │
    │              │                          │ └──────────┘ │                          │              │
    │              │                          │ ┌──────────┐ │                          │              │
    │              │                          │ │    DB    │ │                          │              │
    │              │                          │ │  :5432   │ │                          │              │
    │              │                          │ └──────────┘ │                          │              │
    └──────────────┘                          └──────────────┘                          └──────────────┘
```

---

## 1. Configuration de MetalLB

MetalLB permet d'avoir des LoadBalancer sur bare-metal/minikube.

### Installation
```bash
# Activer MetalLB sur minikube
minikube addons enable metallb

# Configurer la plage d'IP
minikube addons configure metallb
# Entrer la plage: 192.168.49.100 - 192.168.49.120

# Ou appliquer la configuration manuellement
kubectl apply -f metallb/metallb-config.yaml
```

### Vérification
```bash
kubectl get pods -n metallb-system
kubectl get configmap -n metallb-system
```

---

## 2. Configuration de l'Ingress Controller

```bash
# Activer l'Ingress Controller nginx
minikube addons enable ingress

# Vérifier que le controller est actif
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## 3. Déploiement PostgreSQL + PgAdmin (Namespace: bd)

### Déploiement
```bash
# Créer le namespace et les ressources
kubectl apply -f postgresql/namespace.yaml
kubectl apply -f postgresql/postgres-secret.yaml
kubectl apply -f postgresql/postgres-pv.yaml
kubectl apply -f postgresql/postgres-deployment.yaml
kubectl apply -f postgresql/pgadmin-deployment.yaml

# Déployer l'Ingress
kubectl apply -f ingress/pgadmin-ingress.yaml
```

### Vérification
```bash
kubectl get all -n bd
kubectl get ingress -n bd
kubectl get endpoints -n bd
```

### Accès
| Application | URL | Credentials |
|-------------|-----|-------------|
| PgAdmin | http://pgadmin.local | admin@local.dev / admin123 |
| PostgreSQL | postgres.bd.svc:5432 | postgres / postgres123 |

---

## 4. Déploiement Example-Voting-App (Namespace: voting)

L'application de vote Docker avec architecture microservices.

### Architecture
```
┌────────────┐     ┌────────────┐     ┌────────────┐
│    Vote    │────▶│   Redis    │────▶│   Worker   │
│  (Python)  │     │            │     │   (.NET)   │
└────────────┘     └────────────┘     └─────┬──────┘
                                            │
┌────────────┐                        ┌─────▼──────┐
│   Result   │◀───────────────────────│     DB     │
│  (Node.js) │                        │ (Postgres) │
└────────────┘                        └────────────┘
```

### Déploiement
```bash
# Créer le namespace
kubectl apply -f voting-app/namespace.yaml

# Déployer les composants
kubectl apply -f voting-app/redis-deployment.yaml
kubectl apply -f voting-app/db-deployment.yaml
kubectl apply -f voting-app/vote-deployment.yaml
kubectl apply -f voting-app/result-deployment.yaml
kubectl apply -f voting-app/worker-deployment.yaml

# Déployer l'Ingress
kubectl apply -f ingress/voting-app-ingress.yaml
```

### Vérification
```bash
kubectl get all -n voting
kubectl get ingress -n voting
kubectl logs -n voting deployment/worker
```

### Accès
| Application | URL | Description |
|-------------|-----|-------------|
| Vote | http://vote.local | Interface de vote (Cats vs Dogs) |
| Result | http://result.local | Résultats en temps réel |

---

## 5. Déploiement Odoo ERP (Namespace: odoo)

### Déploiement
```bash
# Créer le namespace et les secrets
kubectl apply -f odoo/namespace.yaml
kubectl apply -f odoo/odoo-secret.yaml

# Déployer PostgreSQL pour Odoo
kubectl apply -f odoo/odoo-postgres-deployment.yaml

# Déployer Odoo
kubectl apply -f odoo/odoo-deployment.yaml

# Déployer l'Ingress
kubectl apply -f ingress/odoo-ingress.yaml
```

### Vérification
```bash
kubectl get all -n odoo
kubectl get ingress -n odoo
kubectl logs -n odoo deployment/odoo
```

### Accès
| Application | URL | Description |
|-------------|-----|-------------|
| Odoo | http://odoo.local | ERP Odoo 17 |

---

## 6. Configuration DNS Local

Ajouter les entrées DNS sur votre machine :

```bash
# Obtenir l'IP de minikube
MINIKUBE_IP=$(minikube ip)

# Ajouter au fichier hosts
echo "$MINIKUBE_IP pgadmin.local vote.local result.local odoo.local" | sudo tee -a /etc/hosts
```

### Test avec curl (alternative sans /etc/hosts)
```bash
MINIKUBE_IP=$(minikube ip)
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

# Test PgAdmin
curl -H "Host: pgadmin.local" http://localhost:$INGRESS_PORT

# Test Vote
curl -H "Host: vote.local" http://localhost:$INGRESS_PORT

# Test Result
curl -H "Host: result.local" http://localhost:$INGRESS_PORT

# Test Odoo
curl -H "Host: odoo.local" http://localhost:$INGRESS_PORT
```

---

## 7. Commandes Utiles

### Voir tous les Ingress
```bash
kubectl get ingress --all-namespaces
```

### Voir les services ClusterIP
```bash
kubectl get svc --all-namespaces | grep ClusterIP
```

### Logs des applications
```bash
kubectl logs -n bd deployment/postgres
kubectl logs -n voting deployment/vote
kubectl logs -n odoo deployment/odoo
```

### Nettoyer les ressources
```bash
kubectl delete namespace bd voting odoo
```

---

## 8. Récapitulatif des URLs

| Application | Namespace | Host | Service Port |
|-------------|-----------|------|--------------|
| PgAdmin | bd | pgadmin.local | 80 |
| Vote | voting | vote.local | 80 |
| Result | voting | result.local | 80 |
| Odoo | odoo | odoo.local | 8069 |

---

## 9. Fichiers créés

```
tp-4/
├── metallb/
│   └── metallb-config.yaml
├── postgresql/
│   ├── namespace.yaml
│   ├── postgres-secret.yaml
│   ├── postgres-pv.yaml
│   ├── postgres-deployment.yaml
│   └── pgadmin-deployment.yaml
├── voting-app/
│   ├── namespace.yaml
│   ├── redis-deployment.yaml
│   ├── db-deployment.yaml
│   ├── vote-deployment.yaml
│   ├── result-deployment.yaml
│   └── worker-deployment.yaml
├── odoo/
│   ├── namespace.yaml
│   ├── odoo-secret.yaml
│   ├── odoo-postgres-deployment.yaml
│   └── odoo-deployment.yaml
└── ingress/
    ├── pgadmin-ingress.yaml
    ├── voting-app-ingress.yaml
    └── odoo-ingress.yaml
```

---

## Auteur
Adalbert NANDA
