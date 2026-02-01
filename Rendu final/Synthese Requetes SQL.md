## Travail d'Ulysse

### Création d'un User

Cette procédure gère l'enregistrement d'un nouvel utilisateur. Elle effectue une insertion atomique des données personnelles tout en automatisant la génération de l'horodatage (`register_date`) via la fonction système `NOW()`. Cela garantit que la date de création est déterminée par le serveur de base de données, assurant la précision temporelle de l'inscription.

```sql
CREATE OR REPLACE PROCEDURE create_user(
 p_name_user VARCHAR,
 p_surname VARCHAR,
 p_email VARCHAR,
 p_password CHAR(128)
)
LANGUAGE SQL
AS $$
 INSERT INTO user_ (
 name_user,
 surname,
 email,
 password,
 register_date
 )
 VALUES (
 p_name_user,
 p_surname,
 p_email,
 p_password,
 NOW()
 );
$$;
```

### Connexion en tant qu’User

Cette procédure sécurise l'authentification en agissant comme un filtre strict. Elle recherche une correspondance exacte (`WHERE`) entre l'email et le mot de passe fournis dans la table des utilisateurs. Si les identifiants sont valides, elle retourne l'identifiant unique de l'utilisateur via un paramètre de sortie (`OUT`), ce qui permet à l'application d'initier la session sans exposer d'autres données sensibles.

```sql
CREATE OR REPLACE PROCEDURE authenticate_user(
 p_email VARCHAR,
 p_password CHAR(128),
 OUT p_user_id INT
)
LANGUAGE SQL
AS $$
 SELECT id
 FROM user_
 WHERE email = p_email
 AND password = p_password;
$$;
```

### Insérer un User dans un groupe

Cette procédure permet l'adhésion à un groupe avec une validation de cohérence thématique. Plutôt qu'une insertion simple, elle utilise la clause `INSERT INTO ... SELECT` couplée à une vérification `EXISTS`. Cette logique conditionnelle s'assure que l'utilisateur possède au moins un centre d'intérêt (`likings`) commun avec le tag du groupe avant de valider son adhésion dans la table `membership`.

```sql
CREATE OR REPLACE PROCEDURE join_group(
 p_user_id INT,
 p_group_name VARCHAR
)
LANGUAGE SQL
AS $$
 INSERT INTO membership (id, name_group)
 SELECT p_user_id, g.name_group
 FROM group_ g
 WHERE g.name_group = p_group_name
 AND EXISTS (
 SELECT 1
 FROM likings l
 WHERE l.id = p_user_id
 AND l.tag = g.tag
 );
$$;
```

### Avoir les Users qui interagissent le plus

Cette requête identifie les utilisateurs les plus actifs au sein d'un groupe spécifique. Elle reconstruit la chaîne d'activité via des jointures successives (`JOIN`) reliant le groupe aux posts, puis aux interactions, et enfin aux utilisateurs. Une agrégation (`GROUP BY`) comptabilise le volume total d'interactions par utilisateur, et le résultat est trié par ordre décroissant pour n'extraire que les `N` profils les plus influents (`LIMIT`).

```sql
CREATE OR REPLACE PROCEDURE top_influential_users_in_group(
 p_group_name VARCHAR,
 p_limit INT
)
LANGUAGE SQL
AS $$
 SELECT 
u.id,
 u.name_user,
 u.surname,
 COUNT(*) AS interaction_count
 FROM group_ g
 JOIN post p ON p.tag = g.tag
 JOIN interaction i ON i.id_target_post = p.id
 JOIN user_ u ON u.id = i.id_origin_user
 WHERE g.name_group = p_group_name
 GROUP BY u.id, u.name_user, u.surname
 ORDER BY interaction_count DESC
 LIMIT p_limit;
$$;
```

---

## Travail de Thomas

### Publication d’un contenu avec choix de visibilité

Cette procédure assure l'intégrité des données lors de la création d'un post. Elle exploite le typage fort de PostgreSQL en utilisant un type énuméré (`Visibility`) pour restreindre les valeurs de confidentialité. L'insertion lie automatiquement le contenu à son auteur et son tag via des clés étrangères, tout en déléguant la gestion de l'horodatage à la fonction `NOW()`, garantissant ainsi un historique fiable des publications.

```sql
CREATE OR REPLACE PROCEDURE create_post(
    p_title VARCHAR,
    p_content TEXT,
    p_visibility Visibility,
    p_tag VARCHAR,
    p_author_id INT
)
LANGUAGE SQL
AS $$
    INSERT INTO post (
        title,
        content,
        publish_date,
        visibility,
        tag,
        id_author
    )
    VALUES (
        p_title,
        p_content,
        NOW(),
        p_visibility,
        p_tag,
        p_author_id
    );
$$;
```

### Analyse de réseau (Amis d'amis)

Cette requête complexe utilise des **Common Table Expressions (CTE)** pour structurer une analyse de graphe social à plusieurs niveaux.

1. **Niveau 1 :** Elle identifie d'abord les amis directs via une auto-jointure sur la table `subscribe` (relations réciproques).
2. **Niveau 2 :** Elle étend la recherche aux amis de ces amis, tout en excluant l'utilisateur initial et ses amis directs pour ne garder que les nouvelles connexions potentielles.
3. **Pertinence :** Enfin, une jointure sur `likings` calcule le nombre de centres d'intérêt partagés (`COUNT`) pour trier ces suggestions par affinité.

```sql
CREATE OR REPLACE PROCEDURE friends_of_friends_with_common_interests(
    p_user_id INT
)
LANGUAGE SQL
AS $$
    WITH direct_friends AS (
        SELECT s1.id_subscription AS friend_id
        FROM subscribe s1
        JOIN subscribe s2
          ON s1.id_subscription = s2.id_subscribed
         AND s1.id_subscribed = s2.id_subscription
        WHERE s1.id_subscribed = p_user_id
    ),
    friends_of_friends AS (
        SELECT DISTINCT s.id_subscription AS fof_id
        FROM subscribe s
        JOIN direct_friends df ON s.id_subscribed = df.friend_id
        WHERE s.id_subscription <> p_user_id
          AND s.id_subscription NOT IN (SELECT friend_id FROM direct_friends)
    )
    SELECT 
        u.id,
        u.name_user,
        u.surname,
        COUNT(*) AS common_interests
    FROM friends_of_friends fof
    JOIN user_ u ON u.id = fof.fof_id
    JOIN likings l1 ON l1.id = p_user_id
    JOIN likings l2 ON l2.id = fof.fof_id
                   AND l1.tag = l2.tag
    GROUP BY u.id, u.name_user, u.surname
    ORDER BY common_interests DESC;
$$;
```

### Recommandation de groupes

Ce moteur de recommandation se base sur l'historique comportemental de l'utilisateur. Il relie les interactions passées (`interaction`) aux tags des groupes correspondants via les posts. La requête calcule un score de pertinence basé sur la fréquence d'interaction, tandis qu'une sous-requête avec `NOT IN` assure l'exclusion des groupes dont l'utilisateur est déjà membre (`membership`), favorisant ainsi la découverte de nouvelles communautés.

```sql
CREATE OR REPLACE PROCEDURE recommend_groups_for_user(
    p_user_id INT
)
LANGUAGE SQL
AS $$
    SELECT 
        g.name_group,
        g.tag,
        COUNT(*) AS relevance_score
    FROM interaction i
    JOIN post p ON p.id = i.id_target_post
    JOIN group_ g ON g.tag = p.tag
    WHERE i.id_origin_user = p_user_id
      AND g.name_group NOT IN (
          SELECT name_group
          FROM membership
          WHERE id = p_user_id
      )
    GROUP BY g.name_group, g.tag
    ORDER BY relevance_score DESC;
$$;
```

## Travail d'Erwan

### Calcul de la Portée Indirecte (Viralité)

Cette fonction a pour but de quantifier la viralité réelle d'une publication partagée. L'objectif métier est de distinguer l'audience "gagnée" par le partage de l'audience "naturelle" de l'auteur.

**Mécanique :**
La procédure utilise une série de **Common Table Expressions (CTE)** pour effectuer une opération de soustraction d'ensembles.

1. Elle identifie l'audience du partageur.
2. Elle identifie l'audience de l'auteur original.
3. Elle utilise un filtre `NOT IN` (ou exclusion) pour ne conserver que les utilisateurs uniques apportés par le partageur (ceux qui ne suivaient pas déjà l'auteur).

```sql
/* Structure Simplifiée de la logique */
WITH ShareInteractions AS (
    -- Isolation des partages
    SELECT id_target_post, id_origin_user AS id_sharer 
    FROM interaction WHERE type_interaction = 'Share'
),
IndirectReach AS (
    -- Cœur de l'algorithme : Soustraction des audiences
    SELECT sf.id_target_post, count(sf.id_follower)
    FROM SharerFollowers sf
    WHERE sf.id_follower NOT IN (
        SELECT af.id_follower FROM AuthorFollowers af
    )
)
SELECT ... ORDER BY indirect_reach_count DESC;
```

### Gestion des Abonnements (Ajout et Suppression)

Ces deux procédures stockées gèrent les arêtes du graphe social (les liens *follower/followed*) avec un accent fort sur l'intégrité référentielle.

**Mécanique :**

* **Ajout (`add_subscribe`) :** Avant toute insertion, la procédure valide l'existence physique des deux utilisateurs (l'abonné et la cible) via des blocs conditionnels. Cela empêche la création de liens "orphelins".
* **Suppression (`remove_subscribe`) :** Elle cible précisément la paire unique `(id_subscribed, id_subscription)` pour rompre le lien, incluant une vérification post-exécution pour confirmer la suppression.

```sql
CREATE OR REPLACE PROCEDURE add_subscribe(p_follower_id INT, p_target_id INT)
LANGUAGE SQL
AS $$
    -- Vérification préalable de l'existence des users pour éviter les erreurs FK
    IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_follower_id) THEN ... END IF;

    INSERT INTO subscribe (id_subscribed, id_subscription)
    VALUES (p_target_id, p_follower_id);
$$;

CREATE OR REPLACE PROCEDURE remove_subscribe(p_follower_id INT, p_target_id INT)
LANGUAGE SQL
AS $$
    DELETE FROM subscribe
    WHERE id_subscribed = p_target_id AND id_subscription = p_follower_id;

    -- Validation que la suppression a bien eu lieu
    IF EXISTS (...) THEN RAISE EXCEPTION ... END IF;
$$;
```

### Analyse des Thèmes et Optimisation de la Visibilité

Cette fonction analytique sert d'outil d'aide à la décision pour la stratégie de contenu. Elle ne se contente pas de compter les interactions, elle détermine quel réglage de confidentialité (Public, Privé, etc.) maximise l'engagement pour un sujet donné.

**Mécanique :**
L'algorithme utilise des **fonctions de fenêtrage** (`RANK() OVER PARTITION`).

1. Il calcule le volume total d'interactions par thème (popularité globale).
2. Il segmente ensuite ces interactions par type de visibilité.
3. Il attribue un rang (`RANK`) à chaque type de visibilité au sein d'un même thème.
4. Le filtre final ne retient que le rang `1`, affichant ainsi la configuration la plus performante pour chaque tag.

```sql
WITH ThemeVisibilityCounts AS (
    SELECT
        p.tag,
        p.visibility,
        COUNT(i.id_origin_user) AS vis_count,
        -- Classement des visibilités pour chaque tag
        RANK() OVER (PARTITION BY p.tag ORDER BY COUNT(i.id_origin_user) DESC) as rnk
    FROM post p
    JOIN interaction i ON p.id = i.id_target_post
    GROUP BY p.tag, p.visibility
)
SELECT tc.tag, tc.total_count, tvc.visibility AS best_visibility
FROM ThemeCounts tc
JOIN ThemeVisibilityCounts tvc ON tc.tag = tvc.tag
WHERE tvc.rnk = 1; -- On ne garde que la meilleure stratégie
```

## Travail d'Emmanuel

### Gestion des Interactions Uniques (Like/Share)

Cette procédure encadre l'ajout d'interactions sur les publications. Son rôle principal est de garantir l'unicité des actions binaires (J'aime / Je partage) pour éviter qu'un utilisateur ne puisse artificiellement gonfler les compteurs en répétant la même action sur un même post.

**Mécanique :**
La logique repose sur un mécanisme de "vérification avant insertion".

1. **Filtrage Conditionnel :** Si le type d'interaction est 'like' ou 'share', le système vérifie immédiatement dans la table `interaction` si ce couple (Utilisateur, Post) existe déjà.
2. **Gestion d'Erreur :** Si une antériorité est détectée, une exception est levée (`RAISE EXCEPTION`), bloquant l'opération et retournant un message d'erreur explicite.
3. **Insertion :** Si le champ est libre, l'interaction est enregistrée avec l'horodatage actuel (`NOW()`).

```sql
CREATE OR REPLACE PROCEDURE interact_post(
    post_id INT,
    user_id INT,
    p_interaction_type InteractionType
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Protection contre le spam de Likes/Shares
    IF EXISTS (SELECT 1 FROM interaction WHERE ... ) THEN
        RAISE EXCEPTION 'User ... have already ...';
    END IF;

    -- Insertion validée
    INSERT INTO interaction (...) VALUES (..., NOW());
END;
$$;
```

### Recommandation par Croisement d'Intérêts (Similar Users)

Cette fonction propose des utilisateurs à suivre en se basant sur une méthode de filtrage collaboratif. Elle ne cherche pas simplement des utilisateurs avec les mêmes goûts, mais identifie des profils qui sont "suivis par des gens qui ont les mêmes goûts que la cible".

**Mécanique :**
L'algorithme procède en entonnoir via deux CTE :

1. **Identification des "Jumeaux d'Intérêts" (`same_likings`) :** On isole d'abord les utilisateurs qui partagent les mêmes tags (`likings`) que l'utilisateur cible.
2. **Analyse du Voisinage (`same_likings_users_subscription`) :** On regarde qui ces "jumeaux" suivent. L'hypothèse est que si plusieurs personnes ayant mes goûts suivent un utilisateur X, alors X est probablement pertinent pour moi.
3. **Seuil de Pertinence :** La requête finale ne retient que les profils recommandés par au moins 3 "jumeaux" (`HAVING count > 3`) pour garantir la qualité de la suggestion.

```sql
CREATE OR REPLACE FUNCTION get_similar_users(p_target_user_id INT)
RETURNS TABLE (...) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH same_likings (user_id, common_tag_count) AS (
        -- Étape 1 : Trouver les utilisateurs aux goûts similaires
        SELECT likings.id, count(likings.id) 
        FROM likings 
        WHERE ... AND tag IN (SELECT tag FROM likings WHERE id = p_target_user_id) 
        GROUP BY likings.id
    ),
    same_likings_users_subscription (sub_user_id) AS (
        -- Étape 2 : Qui ces profils similaires suivent-ils ?
        SELECT id_subscription 
        FROM subscribe 
        JOIN (SELECT user_id FROM same_likings WHERE common_tag_count > 3) 
          ON user_id = id_subscribed
    )
    -- Étape 3 : Agrégation et filtrage final
    SELECT sub_user_id, count(sub_user_id) 
    FROM same_likings_users_subscription 
    GROUP BY sub_user_id 
    HAVING count(sub_user_id) > 3 
    ORDER BY sub_user_id;
END;
$$;
```

### Calcul du Score d'Exploration (Interactions Hors-Cercle)

Cette fonction analytique mesure la curiosité d'un utilisateur. Elle calcule un ratio permettant de déterminer si l'utilisateur interagit principalement avec son cercle proche (ses abonnements) ou s'il explore du contenu extérieur (le fil global ou les tendances).

**Mécanique :**
La fonction confronte deux métriques via des CTE :

1. **Interactions Externes (`interactions_of_users_out_of_bound`) :** Elle compte les interactions (`interaction`) sur des posts dont l'auteur **n'est pas** dans la liste d'abonnement de l'utilisateur (`NOT IN ... subscribe`).
2. **Taille du Réseau (`interactions_of_users`) :** Elle compte le nombre total d'interaction 
3. **Ratio Normalisé :** Le calcul final divise le volume d'interactions externes par la taille du réseau. Cela permet de relativiser l'activité : interagir 10 fois hors cercle a plus de valeur pour un utilisateur qui ne suit que 2 personnes que pour un utilisateur qui en suit 1000.

```sql
CREATE OR REPLACE FUNCTION get_users_out_of_bound_interact()
RETURNS TABLE (...) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH interactions_of_users_out_of_bound AS (
        -- Compte les interactions avec des inconnus (Non suivis)
        SELECT u.id, count(*) AS nb_interaction 
        FROM interaction i 
        JOIN post p ON ...
        WHERE p.id_author NOT IN (SELECT id_subscription FROM subscribe ...) 
        GROUP BY u.id
    ),
    interactions_of_users AS ( 
        -- Compte la taille du réseau (Nombre d'abonnements)
        SELECT u.id, count(*) AS nb_interaction 
        FROM user_ u 
        JOIN subscribe s ON u.id = s.id_subscribed 
        GROUP BY u.id
    )
    -- Calcul du ratio : Activité Externe / Taille du Réseau
    SELECT i.id, out_i.nb_interaction::FLOAT / i.nb_interaction 
    FROM interactions_of_users i 
    JOIN interactions_of_users_out_of_bound out_i ON i.id = out_i.id 
    ORDER BY out_of_bound_frequency DESC;
END;
$$;
```
