# Explication Technique : Analyse des Thèmes et Visibilité

Ce document détaille le fonctionnement interne de la fonction SQL `get_theme_stats`. Cette fonction a pour objectif d'analyser quels thèmes (tags) génèrent le plus d'interactions et de déterminer, pour chacun, quel type de visibilité (Public, FollowersOnly, etc.) performe le mieux.

## 1. Définition du Problème

L'objectif est double :

1. Identifier les sujets tendance en comptant le volume total d'interactions.
2. Optimiser la stratégie de contenu en comprenant quelle restriction de visibilité fonctionne le mieux pour chaque sujet.

## 2. Architecture de la Fonction

La fonction est écrite en **PL/pgSQL** et utilise des **Common Table Expressions (CTE)** pour préparer les données avant le résultat final.

### Étape 1 : Volume Global par Thème (`ThemeCounts`)

```sql
ThemeCounts AS (
    SELECT
        p.tag,
        COUNT(i.id_origin_user) AS total_count
    FROM post p
    JOIN interaction i ON p.id = i.id_target_post
    GROUP BY p.tag
)
```

**Rôle** : Cette première étape calcule la popularité brute de chaque tag.

- On joint les tables `post` et `interaction`.
- On groupe par `tag`.
- On compte le nombre total d'interactions, peu importe le type de visibilité.

---

### Étape 2 : Analyse Croisée Thème / Visibilité (`ThemeVisibilityCounts`)

```sql
ThemeVisibilityCounts AS (
    SELECT
        p.tag,
        p.visibility,
        COUNT(i.id_origin_user) AS vis_count,
        RANK() OVER (PARTITION BY p.tag ORDER BY COUNT(i.id_origin_user) DESC) as rnk
    FROM post p
    JOIN interaction i ON p.id = i.id_target_post
    GROUP BY p.tag, p.visibility
)
```

**Rôle** : C'est l'étape la plus complexe. Elle segmente les données plus finement pour trouver la "meilleure" visibilité.

1. **Groupement** : On groupe non seulement par `tag`, mais aussi par `visibility`.
2. **Comptage** : `vis_count` donne le nombre d'interactions pour ce couple (Thème, Visibilité) spécifique.
3. **Classement (`RANK()`)** :
   - `PARTITION BY p.tag` : Le classement recommence à 1 pour chaque nouveau tag.
   - `ORDER BY ... DESC` : La visibilité avec le plus d'interactions reçoit le rang 1.

Cela nous permet de dire : "Pour le thème X, la visibilité Y est n°1, la visibilité Z est n°2...".

---

## 3. Agrégation Finale

```sql
SELECT
    tc.tag,
    tc.total_count,
    tvc.visibility
FROM ThemeCounts tc
JOIN ThemeVisibilityCounts tvc ON tc.tag = tvc.tag
WHERE tvc.rnk = 1
ORDER BY tc.total_count DESC;
```

**Rôle** : On combine les deux résultats précédents.

1. On prend le volume total depuis `ThemeCounts`.
2. On joint avec `ThemeVisibilityCounts` pour récupérer le nom de la visibilité.
3. **Le Filtre Crucial** : `WHERE tvc.rnk = 1`. On ne garde que la ligne gagnante pour chaque thème (celle qui a le plus d'interactions).

## 4. Exemple Illustratif

Imaginons les données suivantes pour le thème **#Tech** :

- Post A (Public) : 100 interactions.
- Post B (Public) : 50 interactions. -> Total Public = 150.
- Post C (Private) : 20 interactions. -> Total Private = 20.

**Exécution :**

1. `ThemeCounts` calcule le total pour **#Tech** : 150 + 20 = **170**.
2. `ThemeVisibilityCounts` classe :
   - #Tech | Public | 150 interactions | **Rang 1**
   - #Tech | Private | 20 interactions | Rang 2
3. La requête finale sélectionne le **Rang 1**.

**Résultat Retourné :**
| theme_name | total_interactions | best_visibility |
| :--- | :--- | :--- |
| #Tech | 170 | Public |
