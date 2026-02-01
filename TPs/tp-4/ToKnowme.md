# TP-4 — Stockage persistant Kubernetes

Ce document constitue le **rapport final complet** du TP-4. Il peut être utilisé comme **README.md**, support de révision, antisèche d’examen et preuve de compréhension.

---

## 🎯 Objectifs du TP

* Comprendre le stockage persistant dans Kubernetes
* Mettre en œuvre des volumes locaux
* Utiliser PersistentVolume (PV) et PersistentVolumeClaim (PVC)
* Vérifier la persistance des données
* Savoir expliquer le mécanisme en contexte d’examen

---

## 🧠 Rappels théoriques

### PersistentVolume (PV)

* Ressource Kubernetes représentant un **stockage physique réel**
* Créé par l’administrateur
* Indépendant des pods
* Définit la capacité, le mode d’accès et le type de stockage

### PersistentVolumeClaim (PVC)

* Demande de stockage faite par une application
* Créée par le développeur
* Kubernetes associe automatiquement le PVC à un PV compatible
* Le pod consomme **uniquement le PVC**

---

## 🔁 Relation PV / PVC (analogie)

* **PV** = appartement
* **PVC** = contrat de location
* **Pod** = locataire

Le pod ne connaît pas le stockage réel, uniquement le PVC.

---

## 📊 Tableau comparatif PV vs PVC

| Élément             | PV             | PVC                 |
| ------------------- | -------------- | ------------------- |
| Créé par            | Administrateur | Développeur         |
| Représente          | Stockage réel  | Besoin en stockage  |
| Consommé par un pod | ❌             | ✅                   |
| Taille              | Fixée          | Demandée            |
| Cycle de vie        | Indépendant    | Lié à l’application |

---

## ⚙️ Ce que Kubernetes a fait automatiquement

1. Le PVC a été créé avec une demande de stockage
2. Kubernetes a recherché un PV compatible selon :

   * StorageClass
   * Capacité suffisante
   * Mode d’accès
3. Le PV correspondant a été trouvé
4. Le PVC est passé de `Pending` à `Bound`
5. Le stockage est prêt avant le démarrage du pod

---

## 🧠 Fiche ultra-courte (à mémoriser)

1. PV = stockage réel du cluster
2. PVC = demande de stockage
3. Le pod utilise un PVC, jamais un PV
4. Kubernetes fait l’association automatiquement
5. Les données persistent même si le pod est supprimé

---

## 🧪 QCM type examen (corrigé)

### Q1. Un pod peut-il utiliser directement un PV ?

❌ Non — il utilise obligatoirement un PVC

### Q2. Que devient un PVC sans PV compatible ?

➡️ Il reste en état `Pending`

### Q3. Un PVC peut-il demander plus que la capacité d’un PV ?

❌ Non

### Q4. Les données sont-elles perdues si le pod est supprimé ?

❌ Non, tant que le PV existe

### Q5. hostPath est-il recommandé en production ?

❌ Non, il est lié à un seul nœud

### Q6. Peut-on partager un PV entre plusieurs pods ?

✅ Oui, si le mode d’accès est `ReadWriteMany`

### Q7. Qui crée le PV et le PVC ?

* PV : administrateur
* PVC : développeur

### Q8. Que signifie un PVC en état `Bound` ?

➡️ Le stockage est prêt à être consommé

### Q9. Le PV est-il lié au pod ?

❌ Non, il est lié au PVC

---

## ✏️ Schéma PV → PVC → Pod (à redessiner)

```
+-------------------+
| PersistentVolume  |
|  (Stockage réel)  |
+-------------------+
          ↑
          | Binding
+-------------------+
| PersistentVolume  |
|      Claim        |
+-------------------+
          ↑
          | Mount
+-------------------+
|        Pod        |
|  (Application)    |
+-------------------+
```

---

## 📝 Phrases clés pour le compte rendu ou l’examen

* « Le pod n’accède jamais directement au stockage mais via un PVC. »
* « Le mécanisme PV/PVC permet d’abstraire la gestion du stockage. »
* « Les données persistent indépendamment du cycle de vie des pods. »

---

## ✅ Conclusion

Le mécanisme **PersistentVolume / PersistentVolumeClaim** est fondamental en Kubernetes pour garantir la persistance, la portabilité et la séparation des responsabilités entre infrastructure et application.

Ce TP démontre une mise en œuvre correcte et conforme aux bonnes pratiques Kubernetes.
