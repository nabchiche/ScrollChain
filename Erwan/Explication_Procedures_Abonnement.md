# Explication Technique : Gestion des Abonnements

Ce document détaille le fonctionnement interne des deux procédures stockées SQL `add_subscribe` et `remove_subscribe`. Ces procédures sont fondamentales pour la gestion du graphe social, permettant aux utilisateurs de s'abonner (suivre) ou de se désabonner d'autres utilisateurs.

## 1. Procédure d'Ajout : `add_subscribe`

Cette procédure permet d'établir une nouvelle relation de suivi entre deux utilisateurs.

### Étape 1 : Vérification de l'Existence des Utilisateurs

```sql
IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_follower_id) THEN
    RAISE EXCEPTION 'User (subscription) with ID % does not exist', p_follower_id;
END IF;

IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_target_id) THEN
    RAISE EXCEPTION 'User (subscribed) with ID % does not exist', p_target_id;
END IF;
```

**Rôle** : Avant de tenter une insertion, la procédure effectue des contrôles d'intégrité. Elle vérifie que :

1. L'utilisateur qui souhaite s'abonner (`p_follower_id`) existe bien dans la table `user_`.
2. L'utilisateur cible (`p_target_id`) existe également.

Si l'une de ces conditions n'est pas remplie, une exception est levée et l'exécution s'arrête, empêchant la corruption des données.

### Étape 2 : Insertion de la Relation

```sql
INSERT INTO subscribe (id_subscribed, id_subscription)
VALUES (p_target_id, p_follower_id);
```

**Rôle** : C'est l'action principale. Une nouvelle ligne est insérée dans la table de liaison `subscribe`.

- `id_subscription` : Représente l'abonné (celui qui fait l'action de suivre).
- `id_subscribed` : Représente la cible (celui qui est suivi).

### Étape 3 : Confirmation de l'Opération

```sql
IF EXISTS (SELECT 1 FROM subscribe WHERE id_subscribed = p_target_id AND id_subscription = p_follower_id) THEN
    RAISE NOTICE 'Subscription successfully added.';
ELSE
    RAISE EXCEPTION 'Failed to add subscription.';
END IF;
```

**Rôle** : Une vérification post-insertion est effectuée pour garantir que l'enregistrement a bien été pris en compte par la base de données.

---

## 2. Procédure de Suppression : `remove_subscribe`

Cette procédure permet de rompre une relation de suivi existante.

### Étape 1 : Vérification de l'Existence

Comme pour l'ajout, la procédure commence par valider que les deux ID fournis correspondent bien à des utilisateurs existants. Cela permet de fournir des messages d'erreur clairs si l'un des utilisateurs est introuvable.

### Étape 2 : Suppression de la Relation

```sql
DELETE FROM subscribe
WHERE id_subscribed = p_target_id AND id_subscription = p_follower_id;
```

**Rôle** : La procédure recherche la ligne spécifique correspondant au couple (Cible, Abonné) dans la table `subscribe` et la supprime. Cela annule l'abonnement.

### Étape 3 : Validation de la Suppression

```sql
IF NOT EXISTS (SELECT 1 FROM subscribe WHERE id_subscribed = p_target_id AND id_subscription = p_follower_id) THEN
    RAISE NOTICE 'Subscription successfully removed.';
ELSE
    RAISE EXCEPTION 'Failed to remove subscription.';
END IF;
```

**Rôle** : Le système vérifie que la ligne n'existe plus. Si elle est toujours présente (par exemple à cause d'un problème de transaction), une erreur est signalée.

---

## 3. Exemple Illustratif

Pour illustrer le fonctionnement concret :

Imaginons deux utilisateurs :

- **Alice** (ID `101`)
- **Bob** (ID `202`)

### Scénario A : Alice s'abonne à Bob

1.  **Appel** : `CALL add_subscribe(101, 202);`
    - `p_follower_id` = 101 (Alice)
    - `p_target_id` = 202 (Bob)
2.  **Vérification** : La base confirme que 101 et 202 existent.
3.  **Action** : Insertion dans `subscribe` : `{id_subscribed: 202, id_subscription: 101}`.
4.  **Résultat** : Alice verra désormais les publications de Bob dans son fil.

### Scénario B : Alice se désabonne de Bob

1.  **Appel** : `CALL remove_subscribe(101, 202);`
2.  **Action** : La base supprime la ligne `{id_subscribed: 202, id_subscription: 101}`.
3.  **Résultat** : Le lien est rompu.
