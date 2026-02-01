# Explication Technique : Calcul de la Portée Indirecte

Ce document détaille le fonctionnement interne de la fonction SQL `get_posts_ordered_by_indirect_reach`. Cette fonction a pour but d'identifier les publications qui ont bénéficié de la plus grande visibilité grâce aux réseaux de connexions (partages), en excluant l'audience déjà acquise par l'auteur original.

## 1. Définition du Problème

L'objectif est de mesurer l'apport _net_ d'un partage.

- **Portée Totale d'un Partage** = Tous les abonnés de la personne qui partage.
- **Portée Directe** = Les abonnés qui suivent _déjà_ l'auteur original du post.
- **Portée Indirecte (Cible)** = Les abonnés du partageur qui **ne suivent pas** l'auteur original.

C'est cette "Portée Indirecte" que nous cherchons à quantifier pour classer les publications.

## 2. Architecture de la Fonction

La fonction est écrite en **PL/pgSQL** et utilise des **Common Table Expressions (CTE)** (clauses `WITH`) pour décomposer le problème en étapes logiques successives.

### Étape 1 : Identification des Partages (`ShareInteractions`)

```sql
WITH ShareInteractions AS (
    SELECT id_target_post, id_origin_user AS id_sharer
    FROM interaction
    WHERE type_interaction = 'Share'
)
```

**Rôle** : Isoler uniquement les interactions de type "Share". On récupère l'identifiant du post partagé et l'identifiant de l'utilisateur qui a partagé (`id_sharer`).

---

### Étape 2 : Identification des Auteurs (`PostAuthors`)

```sql
PostAuthors AS (
    SELECT p.id, p.id_author, u.name_user
    ...
)
```

**Rôle** : Pour chaque post partagé, récupérer qui en est l'auteur original. Cette information est cruciale pour l'étape d'exclusion.

---

### Étape 3 : L'Audience Potentielle (`SharerFollowers`)

```sql
SharerFollowers AS (
    SELECT si.id_target_post, si.id_sharer, s.id_subscribed AS id_follower
    FROM ShareInteractions si
    JOIN subscribe s ON si.id_sharer = s.id_subscription
)
```

**Rôle** : Liste tous les utilisateurs qui voient le post _parce qu'ils suivent le partageur_.

- `s.id_subscription` = Le partageur (celui qu'on suit).
- `s.id_subscribed` = L'abonné (celui qui voit le partage).

---

### Étape 4 : L'Audience Directe (`AuthorFollowers`)

```sql
AuthorFollowers AS (
    SELECT pa.id_post, s.id_subscribed AS id_follower
    FROM PostAuthors pa
    JOIN subscribe s ON pa.id_author = s.id_subscription
)
```

**Rôle** : Liste tous les utilisateurs qui voient le post _parce qu'ils suivent l'auteur original_. Ce sont les utilisateurs qu'il faut **exclure** du calcul.

---

### Étape 5 : Calcul de l'Exclusivité (`IndirectReach`) / Le Cœur de l'Algorithme

```sql
IndirectReach AS (
    SELECT sf.id_target_post, ...
    FROM SharerFollowers sf
    WHERE sf.id_follower NOT IN (
        SELECT af.id_follower
        FROM AuthorFollowers af
        WHERE af.id_post = sf.id_target_post
    )
)
```

1. On prend l'audience du partageur (`SharerFollowers`).
2. On applique un filtre `NOT IN`.
3. On retire tout utilisateur qui se trouve aussi dans la liste des abonnés de l'auteur pour ce post spécifique.

**Note** : On exclut également l'auteur lui-même s'il suit le partageur, pour ne pas fausser les statistiques.

## 3. Agrégation Finale

```sql
SELECT
    p.title,
    COUNT(DISTINCT ir.id_follower) AS indirect_reach_count
...
ORDER BY indirect_reach_count DESC;
```

Une fois la liste filtrée obtenue (c'est-à-dire la liste des "yeux uniques" gagnés), on groupe les résultats par publication et on compte le nombre d'utilisateurs uniques.

## 4. Exemple Illustratif

Imaginons :

- **Alice** (Auteur) poste un article. Elle est suivie par **Bob**.
- **Charlie** (Partageur) partage l'article d'Alice.
- **Charlie** est suivi par **Bob** et **David**.

**Calcul :**

1.  Audience du Partage de Charlie : Bob, David.
2.  Audience de l'Auteur (Alice) : Bob.
3.  Exclusion :
    - Bob suit Charlie ? OUI.
    - Bob suit Alice ? OUI -> **Exclu**.
    - David suit Charlie ? OUI.
    - David suit Alice ? NON -> **Comptabilisé**.

**Résultat** : Portée Indirecte = **1** (David uniquement).

---

Ce mécanisme assure une mesure précise de la viralité réelle apportée par les relais d'influence, sans double comptage.
