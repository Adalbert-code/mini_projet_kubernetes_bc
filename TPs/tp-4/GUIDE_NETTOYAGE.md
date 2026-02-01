# Guide de Nettoyage - TP-4 Avance

Guide complet pour nettoyer les ressources Kubernetes et la VM apres le TP-4.

---

## Table des matieres

1. [Nettoyage Rapide (Script automatique)](#nettoyage-rapide-script-automatique)
2. [Nettoyage Manuel (Commandes detaillees)](#nettoyage-manuel-commandes-detaillees)
3. [Verification du Nettoyage](#verification-du-nettoyage)
4. [Nettoyage Complet (Reset total)](#nettoyage-complet-reset-total)
5. [Gestion de la VM Vagrant](#gestion-de-la-vm-vagrant)

---

## Nettoyage Rapide (Script automatique)

### Dans la VM

```bash
# 1. Se connecter a la VM
vagrant ssh

# 2. Aller dans le repertoire partage
cd /vagrant/tp-4

# 3. Executer le script de nettoyage
chmod +x cleanup.sh
./cleanup.sh
```

Le script fait automatiquement :
- Suppression des namespaces bd, voting, odoo
- Suppression des PersistentVolumes
- Suppression des ressources du namespace default
- Verification qu'il ne reste rien
- Option d'arreter Minikube

---

## Nettoyage Manuel (Commandes detaillees)

### 1. Lister les ressources existantes

```bash
# Voir tout ce qui tourne dans les namespaces TP-4
kubectl get all -n bd
kubectl get all -n voting
kubectl get all -n odoo

# Voir les Ingress
kubectl get ingress --all-namespaces

# Voir les PV/PVC
kubectl get pv
kubectl get pvc --all-namespaces

# Voir les secrets
kubectl get secrets -n bd
kubectl get secrets -n odoo
```

### 2. Supprimer les namespaces (methode recommandee)

Supprimer un namespace supprime TOUTES les ressources qu'il contient.

```bash
# Supprimer le namespace bd (PostgreSQL + PgAdmin)
kubectl delete namespace bd

# Supprimer le namespace voting (Voting App)
kubectl delete namespace voting

# Supprimer le namespace odoo (Odoo ERP)
kubectl delete namespace odoo

# Verifier
kubectl get namespaces
```

### 3. Supprimer les PersistentVolumes

Les PV ne sont pas dans un namespace, ils doivent etre supprimes separement.

```bash
# Lister les PV
kubectl get pv

# Supprimer les PV du TP-4
kubectl delete pv postgres-pv

# Verifier
kubectl get pv
```

### 4. Supprimer les Ingress (si namespace deja supprime, pas necessaire)

```bash
kubectl delete ingress pgadmin-ingress -n bd
kubectl delete ingress voting-app-ingress -n voting
kubectl delete ingress odoo-ingress -n odoo
```

### 5. Nettoyer le namespace default (si utilise)

```bash
kubectl delete pods --all -n default
kubectl delete deployments --all -n default
kubectl delete services --all -n default
kubectl delete replicasets --all -n default
```

### 6. Arreter Minikube (optionnel)

```bash
minikube stop
```

---

## Verification du Nettoyage

### Verifier les namespaces

```bash
kubectl get namespaces
```

**Resultat attendu (seulement les namespaces systeme):**
```
NAME                   STATUS   AGE
default                Active   XXd
ingress-nginx          Active   XXd
kube-node-lease        Active   XXd
kube-public            Active   XXd
kube-system            Active   XXd
metallb-system         Active   XXd
```

### Verifier les pods

```bash
kubectl get pods --all-namespaces | grep -E "bd|voting|odoo"
```

**Resultat attendu:** Aucun resultat

### Verifier les PV

```bash
kubectl get pv
```

**Resultat attendu:** Aucun PV ou seulement des PV systeme

### Verifier les Ingress

```bash
kubectl get ingress --all-namespaces
```

**Resultat attendu:** Aucun Ingress

### Verifier qu'il ne reste rien

```bash
# Commande complete de verification
kubectl get all,ingress,pv,pvc,secrets --all-namespaces | grep -E "bd|voting|odoo"
```

**Resultat attendu:** Aucun resultat

---

## Nettoyage Complet (Reset total)

### Option 1 : Supprimer uniquement Minikube

```bash
# Dans la VM
sudo minikube delete --all --purge

# Nettoyer les fichiers temporaires
sudo rm -rf ~/.minikube
sudo rm -rf /root/.minikube
sudo rm -rf /tmp/minikube*
sudo rm -rf /tmp/juju-*

# Nettoyer les donnees persistantes
sudo rm -rf /data/postgres

# Verifier
minikube status
# Resultat : Profile "minikube" not found
```

### Option 2 : Reset complet Minikube + reinstallation

```bash
# Tout supprimer
sudo minikube delete --all --purge
sudo rm -rf ~/.minikube /root/.minikube
sudo rm -rf ~/.kube /root/.kube
sudo rm -rf /tmp/minikube* /tmp/juju-*
sudo rm -rf /etc/kubernetes
sudo rm -rf /data/postgres

# Reinstaller Minikube
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

# Verifier
kubectl get nodes
```

### Option 3 : Reinstaller avec les addons

Apres le reset complet:
```bash
# Activer les addons necessaires
minikube addons enable ingress
minikube addons enable metallb

# Attendre l'Ingress Controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verifier
minikube addons list | grep -E "ingress|metallb"
kubectl get pods -n ingress-nginx
```

---

## Gestion de la VM Vagrant

### Arreter la VM (depuis Windows)

```powershell
# Aller dans le repertoire du projet
cd C:\Users\adaln\EAZYTRAINING\DevOpsBootCamps\kubernetes\kubernetes-training

# Arreter la VM proprement
vagrant halt

# Verifier le statut
vagrant status
```

### Redemarrer la VM

```powershell
# Depuis le repertoire du projet
vagrant up

# Se connecter
vagrant ssh
```

### Supprimer completement la VM

```powershell
# Attention : supprime TOUTE la VM
vagrant destroy -f

# Pour recreer une VM propre
vagrant up
```

### Sauvegarder l'etat de la VM

```powershell
# Sauvegarder l'etat actuel (suspend)
vagrant suspend

# Reprendre
vagrant resume
```

---

## Etats de la VM et leurs commandes

| Etat souhaite | Commande | Description |
|---------------|----------|-------------|
| Arreter proprement | `vagrant halt` | Eteint la VM, disque preserve |
| Suspendre | `vagrant suspend` | Met en pause, RAM sauvegardee |
| Supprimer | `vagrant destroy -f` | Supprime completement la VM |
| Redemarrer | `vagrant reload` | Equivalent a halt + up |
| Reprovisioner | `vagrant provision` | Reexecute le script d'installation |
| Etat complet | `vagrant up` | Demarre ou cree la VM |

---

## Scenarios Courants

### Scenario 1 : Je veux juste nettoyer les apps du TP-4

```bash
# Dans la VM
vagrant ssh
cd /vagrant/tp-4
./cleanup.sh
exit

# La VM reste demarree, Minikube peut rester actif
```

### Scenario 2 : Je veux arreter la VM pour economiser des ressources

```powershell
# Sur Windows
cd C:\Users\adaln\EAZYTRAINING\DevOpsBootCamps\kubernetes\kubernetes-training
vagrant halt
```

### Scenario 3 : Je veux tout recommencer a zero

```powershell
# Sur Windows - Supprimer la VM
vagrant destroy -f

# Recreer une VM propre
vagrant up

# Se connecter
vagrant ssh

# Verifier que tout fonctionne
kubectl get nodes

# Redeployer le TP-4
cd /vagrant/tp-4
./deploy-all.sh
```

### Scenario 4 : Le TP-4 est casse, je veux le redeployer

```bash
# Dans la VM - Nettoyer d'abord
cd /vagrant/tp-4
./cleanup.sh
# Repondre 'n' pour garder Minikube actif

# Attendre que les namespaces soient supprimes
watch kubectl get namespaces

# Redeployer
./deploy-all.sh
```

### Scenario 5 : Minikube est casse, je veux le reinstaller

```bash
# Dans la VM
sudo minikube delete --all --purge
sudo rm -rf ~/.minikube /root/.minikube /tmp/minikube*

# Redemarrer Minikube
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

# Activer les addons
minikube addons enable ingress
minikube addons enable metallb

# Attendre l'Ingress Controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Redeployer le TP-4
cd /vagrant/tp-4
./deploy-all.sh
```

---

## Verifications Post-Nettoyage

### Checklist complete

```bash
# 1. Pas de namespaces TP-4
kubectl get ns | grep -E "bd|voting|odoo"
# Attendu: aucun resultat

# 2. Pas de pods TP-4
kubectl get pods -A | grep -E "bd|voting|odoo"
# Attendu: aucun resultat

# 3. Pas de PV TP-4
kubectl get pv | grep postgres
# Attendu: aucun resultat

# 4. Pas d'Ingress TP-4
kubectl get ingress -A
# Attendu: aucun resultat

# 5. Cluster sain (si Minikube tourne)
kubectl cluster-info
kubectl get nodes
# Node doit etre Ready

# 6. Ressources systeme OK
kubectl get pods -n kube-system
kubectl get pods -n ingress-nginx
# Tous les pods systeme en Running
```

---

## Erreurs Courantes et Solutions

### Namespace bloque en "Terminating"

```bash
# Voir le statut
kubectl get namespace <namespace-name>

# Si bloque, forcer la suppression
kubectl get namespace <namespace-name> -o json > tmp.json
# Editer tmp.json et retirer "finalizers": [...]
kubectl replace --raw "/api/v1/namespaces/<namespace-name>/finalize" -f ./tmp.json
rm tmp.json
```

### Pod bloque en "Terminating"

```bash
# Forcer la suppression
kubectl delete pod <pod-name> -n <namespace> --force --grace-period=0
```

### Erreur "connection refused" apres cleanup

```bash
# Minikube probablement arrete, le redemarrer
sudo minikube start --driver=none --container-runtime=containerd --force
sudo chown -R vagrant:vagrant ~/.kube ~/.minikube
sed -i "s|/root|$HOME|g" ~/.kube/config
```

---

## Resume des Commandes Essentielles

```bash
# NETTOYAGE RAPIDE (namespaces seulement)
kubectl delete namespace bd voting odoo
kubectl delete pv postgres-pv

# VERIFICATION
kubectl get ns | grep -E "bd|voting|odoo"
kubectl get all,ingress,pv -A | grep -E "bd|voting|odoo"

# NETTOYAGE + ARRET MINIKUBE
./cleanup.sh

# RESET COMPLET MINIKUBE
sudo minikube delete --all --purge

# RESET COMPLET VM (depuis Windows)
vagrant destroy -f && vagrant up

# REDEPLOIEMENT APRES NETTOYAGE
cd /vagrant/tp-4 && ./deploy-all.sh
```

---

## Nettoyage du fichier hosts Windows

Apres le TP, pensez a nettoyer votre fichier hosts Windows:

```powershell
# Ouvrir en Administrateur
notepad C:\Windows\System32\drivers\etc\hosts

# Supprimer ou commenter ces lignes:
# 192.168.56.10 pgadmin.local vote.local result.local odoo.local

# Vider le cache DNS
ipconfig /flushdns
```

---

## Bonnes Pratiques

1. **Toujours verifier** avant de tout supprimer
   ```bash
   kubectl get all -A
   ```

2. **Utiliser le script cleanup.sh** pour eviter d'oublier des ressources

3. **Supprimer par namespace** plutot que ressource par ressource

4. **Arreter Minikube** quand vous ne l'utilisez pas (economise ressources)

5. **Documenter** vos modifications pour pouvoir les reproduire

---

**Nettoyage termine !**

Votre VM est maintenant propre et prete pour le prochain TP ou pour etre arretee.

---

## Auteur

Adalbert NANDA - Janvier 2026
