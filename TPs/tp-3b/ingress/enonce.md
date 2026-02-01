#### Ingress (minikube) 

– liens utiles
    https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

    https://kubernetes.github.io/ingress-nginx/deploy/#provider-specific-steps

###################################    Enable the Ingress controller    ###################################

```bash
minikube addons enable ingress
```
```bash
kubectl get pods -n ingress-nginx
```

###################################    Deploy a hello, world app    ###################################

```bash
kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
```
```bash
kubectl expose deployment web --type=NodePort --port=8080
```
```bash
kubectl get service web
```
```bash
minikube service web --url
```

###################################    Create an Ingress Rule    ###################################

```bash
vi example-ingress.yaml
```

Copy and paste

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
    - host: hello-world.info
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8080
```

```bash
kubectl apply -f example-ingress.yaml
```

```bash
curl --resolve "hello-world.info:80:$( minikube ip )" -i http://hello-world.info
```

###################################    Create a second Deployment    ###################################

```bash
kubectl create deployment web2 --image=gcr.io/google-samples/hello-app:2.0
```

```bash
kubectl expose deployment web2 --port=8080 --type=NodePort
```

Update ingress rule

```bash
vi example-ingress.yaml
```

```bash
- path: /v2
  pathType: Prefix
  backend:
    service:
      name: web2
      port:
        number: 8080
```

```bash
kubectl apply -f example-ingress.yaml
```

```bash
curl --resolve "hello-world.info:80:$( minikube ip )" -i http://hello-world.info
```

```bash
curl --resolve "hello-world.info:80:$( minikube ip )" -i http://hello-world.info/v2
```

###################################    Webapp Color avec Ingress    ###################################

Cette section utilise les pods simple-webapp-color (red et blue) du TP-3b avec un Ingress pour router le trafic.

**Architecture :**
```
                        webapp.local
                             |
                    +--------+--------+
                    |        |        |
                   /red    /blue      /
                    |        |        |
              service-red  service-blue  service-nodeport-web
                    |        |        |
               pod-red   pod-blue   (les deux)
```

**1. Activer l'Ingress Controller**
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

**2. Déployer les pods avec labels de couleur**
```bash
kubectl apply -f ../namespace.yml
kubectl apply -f ../pod-red.yml
kubectl apply -f ../pod-blue.yml
kubectl apply -f ../service-nodeport-web.yml
```

**3. Créer les services individuels pour red et blue**
```bash
kubectl apply -f service-red.yaml
kubectl apply -f service-blue.yaml
```

**4. Déployer l'Ingress**
```bash
kubectl apply -f webapp-ingress.yaml
```

**5. Vérifier les ressources**
```bash
kubectl get ingress -n production
kubectl get svc -n production
kubectl get endpoints -n production
```

**6. Ajouter l'entrée DNS (sur la VM)**
```bash
echo "$(minikube ip) webapp.local" | sudo tee -a /etc/hosts
```

**7. Tester les routes**
```bash
# Route par défaut (load balance entre red et blue)
curl http://webapp.local

# Route spécifique vers le pod rouge
curl http://webapp.local/red

# Route spécifique vers le pod bleu
curl http://webapp.local/blue
```

**8. Test avec resolve (alternative sans modifier /etc/hosts)**
```bash
curl --resolve "webapp.local:80:$(minikube ip)" http://webapp.local
curl --resolve "webapp.local:80:$(minikube ip)" http://webapp.local/red
curl --resolve "webapp.local:80:$(minikube ip)" http://webapp.local/blue
```

**Fichiers créés :**
- `webapp-ingress.yaml` - Règles Ingress pour router /red, /blue et /
- `service-red.yaml` - Service ClusterIP pour le pod rouge
- `service-blue.yaml` - Service ClusterIP pour le pod bleu

