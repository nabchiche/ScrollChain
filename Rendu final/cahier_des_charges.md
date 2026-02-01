# Cahier des Charges : Conception de la Base de Données

**Projet :** ScrollChain
**Date :** 07/01/2026
**Auteurs :** Ulysse VANDAMME, Thomas BOISSON, Erwan NICOLAS, Emmanuel VERMOREL

---

## 1. Contexte et Objectifs

* **Sujet général :** Gestion et analyse structurée des flux d’informations d’un réseau social décentralisé.
* **Objectif :** La base de données doit permettre de gérer le flux de connexions (amis, abonnés), les publications et les interactions dans le but d'analyser les comportements, les influences et les centres d'intérêt.
* **Spécificité du réseau :** Les liens entre les personnes sont considérés comme étant motivés par des centres d'intérêt communs, au-delà des liens familiaux ou amicaux externes.

---

## 2. Dictionnaire des Données

### 2.1. Les Acteurs

* **Utilisateur** :
    * **Données à stocker :** Id, Nom, Prénom, Email (unique), Mot de passe (hashé), Date d'inscription, Centres d'intérêts (calculés ou déclarés).
    * **Relations :**
        * *Abonnements* : Liste des utilisateurs suivis.
        * *Amis* : Relation bidirectionnelle (abonnement mutuel).
        * *Appartenance Groupe* : Liste des groupes rejoints.

### 2.2. Les Objets / Services

* **Publication** :
    * **Données à stocker :** Titre, Contenu textuel, Thème (catégorie générale), Date, Visibilité (Enum), Métriques (compteurs de vues/likes/partages).
    * **Relations :** Auteur (Un seul utilisateur par publication).
* **Groupe** :
    * **Données à stocker :** Nom du groupe, Thématique principale.
    * **Relations :** Membres (Utilisateurs inscrits).

### 2.3. Les Événements / Transactions

* **Interaction (Sociale)** :
    * **Données à stocker :** Type d'interaction (Like, Partage, Commentaire), Date.
    * **Relations :** Auteur (Utilisateur), Cible (Publication).
* **Message (Communication)** :
    * **Données à stocker :** Contenu, Date d'envoi.
    * **Relations :** Expéditeur (Utilisateur), Destinataire (Utilisateur).

---

## 3. Règles de Gestion

> **Liste des contraintes logiques et règles métier définissant le comportement du système.**

**Règles liées aux Utilisateurs et Connexions :**
1. Un **Utilisateur** est identifié de manière unique par son email.
2. Un **Abonné** est une connexion unidirectionnelle (A suit B).
3. Un **Ami** est défini strictement comme une connexion bidirectionnelle (A suit B ET B suit A).
4. Un Utilisateur acquiert un **Centre d'intérêt** si :
    * Il cumule un nombre défini de "Likes" sur des publications portant sur ce thème.
    * OU SI plusieurs membres de son entourage (Amis) possèdent déjà ce centre d'intérêt (logique de contagion sociale).

**Règles liées aux Publications et Visibilité :**
5. Une **Publication** est rédigée par un seul **Auteur**.
6. Le **Contenu** d'une publication est associé à un **Thème** général unique.
7. La **Visibilité** d'une publication doit être choisie parmi trois options :
    * *Amis uniquement* (Cercle restreint).
    * *Amis et Abonnés* (Cercle étendu).
    * *Privé* (Optionnel / Visible uniquement par l'auteur).

**Règles liées aux Groupes :**
8. Pour rejoindre un **Groupe**, un Utilisateur doit obligatoirement posséder le **Thème** du groupe parmi ses centres d'intérêt (validé par la règle n°4).

**Règles liées aux Communications :**
9. Un Utilisateur peut envoyer un **Message** privé uniquement si le destinataire fait partie :
    * De ses Amis.
    * De ses Abonnés.
    * Ou s'ils sont tous deux membres du même **Groupe**.

---

## 4. Fonctionnalités attendues (Vue Base de Données)

### 4.1. Opérations courantes

* Création de comptes et authentification.
* Publication d'un contenu avec choix de visibilité.
* Gestion des abonnements (suivre/ne plus suivre).
* Action de "Liker" ou "Commenter" une publication (mise à jour des compteurs et de l'historique).
* Adhésion à un groupe thématique (avec vérification préalable des centres d'intérêt).

### 4.2. Requêtes complexes (Analyses)

La base doit permettre de répondre aux questions stratégiques suivantes :

1. **Analyse de réseau :** Quels utilisateurs ont des connexions indirectes (amis d'amis) avec un utilisateur donné, et quels sont leurs intérêts communs ?
2. **Engagement de groupe :** Quels groupes thématiques génèrent le plus d'interactions et quel type de publication y fonctionne le mieux ?
3. **Intégration :** Comment suggérer des connexions à un nouvel utilisateur pour l'intégrer au réseau existant ?
4. **Influence :** Quels utilisateurs influencent le plus les interactions au sein d'un groupe spécifique ?
5. **Recommandation :** Quels groupes ou connexions recommander à un utilisateur en fonction de son activité récente (Likes, commentaires) ?
6. **Viralité :** Quelles publications ont maximisé leur portée via des partages indirects (réseaux de connexions) ?
7. **Exploration :** Quels utilisateurs interagissent fréquemment en dehors de leur cercle direct (Amis/Abonnés) ?

---

## 5. Contraintes Techniques et Volumétrie

* **SGBD retenu :** PostgreSQL.
* **Type de modélisation :** Relationnelle (SQL).
* **Conventions de nommage :**
    * Tables : `snake_case`, singulier (ex: `utilisateur`, `publication_groupe`).
    * Clés primaires : `id` (auto-incrément ou UUID).
    * Clés étrangères : `nom_table_id` (ex: `utilisateur_id`).

---

## 6. Livrables Attendus

Dans le cadre de ce projet d'étude, les éléments suivants seront fournis :

1. **Dictionnaire des données complet** (Ce document mis à jour).
2. **MCD** (Modèle Conceptuel de Données - Schéma Entité/Association).
3. **MLD** (Modèle Logique de Données - Schéma Relationnel normalisé).
4. **Script SQL de création** (DDL : `CREATE TABLE`, contraintes `FOREIGN KEY`).
5. **Jeu de données de test** (Script `INSERT` avec des données fictives cohérentes pour valider les règles de gestion).
6. **Script de requêtes** (Les requêtes SQL répondant aux besoins du point 4.2).
