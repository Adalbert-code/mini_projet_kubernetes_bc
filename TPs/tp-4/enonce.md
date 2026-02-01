#### TP4: GESTION DU STOCKAGE (minikube et [eazylabs](http://docker.labs.eazytraining.fr/)) 

VOLUME
```bash
kubectl apply -f mysql-volume.yml
```
```bash
kubectl get po -o wide
```
```bash
kubectl port-forward mysql-volume 3306:3306 --address 0.0.0.0
```

APPLY VOLUME
```bash
kubectl get po -o wide
```
```bash
kubectl delete  -f mysql-volume.yml
```
```bash
kubectl get po -o wide
```

PV
```bash
kubectl apply -f pv.yml
```
```bash
kubectl get pv -o wide
```
```bash
kubectl get pv pv -o wide
```
```bash
kubectl describe  pv pv
```

PVC
```bash
kubectl apply -f pvc.yml
```
```bash
kubectl get pvc pvc -o wide
```
```bash
kubectl describe  pv pv
```

APPLY PV AND PVC
```bash
kubectl apply -f mysql-pv.yml
```
```bash
kubectl describe  po mysql-pv
```
```bash
kubectl get po
```
---------------------------------------------------------------------------------------------------
```
vagrant@minikube:/vagrant/tp-4$ kubectl apply -f mysql-volume.yml
pod/mysql-volume created
vagrant@minikube:/vagrant/tp-4$ kubectl get pod mysql-volume
NAME           READY   STATUS    RESTARTS   AGE
mysql-volume   1/1     Running   0          12s
vagrant@minikube:/vagrant/tp-4$ kubectl describe pod mysql-volume
Name:             mysql-volume
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/10.0.2.15
Start Time:       Sun, 25 Jan 2026 17:47:28 +0000
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.244.0.22
IPs:
  IP:  10.244.0.22
Containers:
  mysql:
    Container ID:   containerd://b57767fb0d738b3173cd543109b6ea16fec97f567c4509901a83ed57e062b4f8
    Image:          mysql
    Image ID:       docker.io/library/mysql@sha256:6b18d01fb632c0f568ace1cc1ebffb42d1d21bc1de86f6d3e8b7eb18278444d9
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sun, 25 Jan 2026 17:47:30 +0000
    Ready:          True
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  password
      MYSQL_DATABASE:       eazytraining
      MYSQL_USER:           eazy
      MYSQL_PASSWORD:       eazy
    Mounts:
      /var/lib/mysql from mysql-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-xppvm (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  mysql-data:
    Type:          HostPath (bare host directory volume)
    Path:          /data-volume
    HostPathType:  DirectoryOrCreate
  kube-api-access-xppvm:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  50s   default-scheduler  Successfully assigned default/mysql-volume to minikube
  Normal  Pulling    49s   kubelet            Pulling image "mysql"
  Normal  Pulled     48s   kubelet            Successfully pulled image "mysql" in 1s (1s including waiting). Image size: 266392215 bytes.
  Normal  Created    48s   kubelet            Created container mysql
  Normal  Started    48s   kubelet            Started container mysql
vagrant@minikube:/vagrant/tp-4$ 
vagrant@minikube:/vagrant/tp-3b$ kubectl get pods -n ingress-nginx
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-fdv5x        0/1     Completed   0          2m26s
ingress-nginx-admission-patch-hkbhp         0/1     Completed   1          2m26s
ingress-nginx-controller-576cdbb6db-2vk67   1/1     Running     0          2m26s
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/namespace.yml
namespace/production configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/pod-red.yml
pod/simple-webapp-color-red configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/pod-blue.yml
pod/simple-webapp-color-blue configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/service-nodeport-web.yml
service/service-nodeport-web configured
namespace/production configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/pod-red.yml
pod/simple-webapp-color-red configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/pod-blue.yml
pod/simple-webapp-color-blue configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/service-nodeport-web.yml
service/service-nodeport-web configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/pod-red.yml
pod/simple-webapp-color-red configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/pod-blue.yml
pod/simple-webapp-color-blue configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/service-nodeport-web.yml
service/service-nodeport-web configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/service-nodeport-web.yml
service/service-nodeport-web configured
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/ingress/service-red.yaml
service/service-red created
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/ingress/service-blue.yaml
service/service-blue created
service/service-blue created
vagrant@minikube:/vagrant/tp-3b$ kubectl apply -f /vagrant/tp-3b/ingress/webapp-ingress.yaml
ingress.networking.k8s.io/webapp-ingress created
vagrant@minikube:/vagrant/tp-3b$ cd ../tp-4
vagrant@minikube:/vagrant/tp-4$ ls -la
ingress.networking.k8s.io/webapp-ingress created
vagrant@minikube:/vagrant/tp-3b$ cd ../tp-4
vagrant@minikube:/vagrant/tp-4$ ls -la
total 11
drwxrwxrwx 1 vagrant vagrant    0 Nov  6 19:37 .
ingress.networking.k8s.io/webapp-ingress created
vagrant@minikube:/vagrant/tp-3b$ cd ../tp-4
vagrant@minikube:/vagrant/tp-4$ ls -la
total 11
vagrant@minikube:/vagrant/tp-4$ ls -la
total 11
drwxrwxrwx 1 vagrant vagrant    0 Nov  6 19:37 .
drwxrwxrwx 1 vagrant vagrant 4096 Jan 25 13:55 ..
-rwxrwxrwx 1 vagrant vagrant  843 Nov  6 19:37 enonce.md
-rwxrwxrwx 1 vagrant vagrant  500 Nov  6 19:37 mysql-pv.yml
-rwxrwxrwx 1 vagrant vagrant  526 Nov  6 19:37 mysql-volume.yml
-rwxrwxrwx 1 vagrant vagrant  234 Nov  6 19:37 pv.yml
-rwxrwxrwx 1 vagrant vagrant  526 Nov  6 19:37 mysql-volume.yml
-rwxrwxrwx 1 vagrant vagrant  234 Nov  6 19:37 pv.yml
-rwxrwxrwx 1 vagrant vagrant  234 Nov  6 19:37 pv.yml
-rwxrwxrwx 1 vagrant vagrant  192 Nov  6 19:37 pvc.yml
vagrant@minikube:/vagrant/tp-4$ kubectl apply -f pv.yml
-rwxrwxrwx 1 vagrant vagrant  192 Nov  6 19:37 pvc.yml
vagrant@minikube:/vagrant/tp-4$ kubectl apply -f pv.yml
persistentvolume/pv created
vagrant@minikube:/vagrant/tp-4$ kubectl apply -f pv.yml
persistentvolume/pv created
persistentvolume/pv created
vagrant@minikube:/vagrant/tp-4$ kubectl get pv

vagrant@minikube:/vagrant/tp-4$ kubectl get pv


NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv     1Gi        RWO            Retain           Available           manual         <unset>                          65s
vagrant@minikube:/vagrant/tp-4$
vagrant@minikube:/vagrant/tp-4$
vagrant@minikube:/vagrant/tp-4$ kubectl apply -f pvc.yml
persistentvolumeclaim/pvc created
vagrant@minikube:/vagrant/tp-4$ kubectl get pvc
NAME   STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
pvc    Bound    pv       1Gi        RWO            manual         <unset>                 21s
vagrant@minikube:/vagrant/tp-4$ kubectl apply -f mysql-pv.yml
pod/mysql-pv created
vagrant@minikube:/vagrant/tp-4$ kubectl get pod mysql-pv
NAME       READY   STATUS              RESTARTS   AGE
mysql-pv   0/1     ContainerCreating   0          12s
vagrant@minikube:/vagrant/tp-4$ kubectl describe pod mysql-pv
Name:             mysql-pv
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/10.0.2.15
Start Time:       Sun, 25 Jan 2026 17:33:38 +0000
Labels:           <none>
Annotations:      <none>
Status:           Pending
IP:
IPs:              <none>
Containers:
  mysql:
    Container ID:
    Image:          mysql
    Image ID:
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  password
      MYSQL_DATABASE:       eazytraining
      MYSQL_USER:           eazy
      MYSQL_PASSWORD:       eazy
    Mounts:
      /var/lib/mysql from mysql-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2j7n7 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   False
  Initialized                 True
  Ready                       False
  ContainersReady             False
  PodScheduled                True
Volumes:
  mysql-data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc
    ReadOnly:   false
  kube-api-access-2j7n7:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  27s   default-scheduler  Successfully assigned default/mysql-pv to minikube
  Normal  Pulling    25s   kubelet            Pulling image "mysql"
vagrant@minikube:/vagrant/tp-4$ kubectl get pod mysql-pv
NAME       READY   STATUS              RESTARTS   AGE
mysql-pv   0/1     ContainerCreating   0          44s
vagrant@minikube:/vagrant/tp-4$ kubectl describe pod mysql-pv
Name:             mysql-pv
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/10.0.2.15
Start Time:       Sun, 25 Jan 2026 17:33:38 +0000
Labels:           <none>
Annotations:      <none>
Status:           Pending
IP:
IPs:              <none>
Containers:
  mysql:
    Container ID:
    Image:          mysql
    Image ID:
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  password
      MYSQL_DATABASE:       eazytraining
      MYSQL_USER:           eazy
      MYSQL_PASSWORD:       eazy
    Mounts:
      /var/lib/mysql from mysql-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2j7n7 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   False
  Initialized                 True
  Ready                       False
  ContainersReady             False
  PodScheduled                True
Volumes:
  mysql-data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc
    ReadOnly:   false
  kube-api-access-2j7n7:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  67s   default-scheduler  Successfully assigned default/mysql-pv to minikube
  Normal  Pulling    65s   kubelet            Pulling image "mysql"
vagrant@minikube:/vagrant/tp-4$ kubectl describe pod mysql-pv
Name:             mysql-pv
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/10.0.2.15
Start Time:       Sun, 25 Jan 2026 17:33:38 +0000
Labels:           <none>
Annotations:      <none>
Status:           Pending
IP:
IPs:              <none>
Containers:
  mysql:
    Container ID:
    Image:          mysql
    Image ID:
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  password
      MYSQL_DATABASE:       eazytraining
      MYSQL_USER:           eazy
      MYSQL_PASSWORD:       eazy
    Mounts:
      /var/lib/mysql from mysql-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2j7n7 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   False
  Initialized                 True
  Ready                       False
  ContainersReady             False
  PodScheduled                True
Volumes:
  mysql-data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc
    ReadOnly:   false
  kube-api-access-2j7n7:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  4m46s  default-scheduler  Successfully assigned default/mysql-pv to minikube
  Normal  Pulling    4m44s  kubelet            Pulling image "mysql"
vagrant@minikube:/vagrant/tp-4$ kubectl get pod mysql-pv
NAME       READY   STATUS              RESTARTS   AGE
mysql-pv   0/1     ContainerCreating   0          5m14s
vagrant@minikube:/vagrant/tp-4$ kubectl get pod mysql-pv
NAME       READY   STATUS              RESTARTS   AGE
mysql-pv   0/1     ContainerCreating   0          6m45s
vagrant@minikube:/vagrant/tp-4$ kubectl get pod mysql-pv
NAME       READY   STATUS    RESTARTS   AGE
mysql-pv   1/1     Running   0          9m20s
vagrant@minikube:/vagrant/tp-4$ 
```
-------------------------------------------------------------------------------------------------
▶️ Déploiement
kubectl apply -f mysql-pv.yml
kubectl get pod mysql-pv

🔍 Vérification finale du stockage
kubectl describe pod mysql-pv


On doit voir :

PersistentVolumeClaim: mysql-pvc


Test de la persistance :

kubectl delete pod mysql-pv
kubectl apply -f mysql-pv.yml


👉 La base est toujours là ✅

📝 Expression compte rendu

« Le stockage persistant est assuré soit par un volume local (hostPath), soit par un PersistentVolume consommé via un PersistentVolumeClaim. Les données MySQL restent persistantes même après suppression du pod. »