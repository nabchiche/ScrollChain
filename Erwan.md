# Travail sur les procédures d'abonnement et de désabonnement ainsi que sur les statistiques des thèmes
### Par Erwan Nicolas

Ce document explique le code ajouté pour gérer les abonnements et analyser les données.

## 1. Les Procédures Stockées (Actions)

Ce sont des commandes prêtes à l'emploi pour effectuer des actions courantes.

- **`add_subscribe(suiveur, suivi)`** : Permet à un utilisateur de s'abonner à un autre. Elle vérifie que les deux utilisateurs existent et qu'on ne s'abonne pas à soi-même.
- **`remove_subscribe(suiveur, suivi)`** : Permet de se désabonner. Elle vérifie que l'abonnement existait bien avant de le supprimer.

## 2. La Fonction d'Analyse (Calculs)

- **`get_theme_stats()`** : Cette fonction analyse les données pour répondre à la question : _"Quels thèmes marchent le mieux et comment ?"_
  - Elle compte toutes les interactions (likes, partages, etc.) par thème (ex: Technologie, Cuisine).
  - Pour chaque thème, elle regarde si ce sont les posts "Publics", "Amis" ou "Abonnés" qui ont le plus de succès.
  - Elle retourne une liste classée du thème le plus populaire au moins populaire.

## 3. Les Tests (Vérification)

Les tests servent à s'assurer que tout fonctionne comme prévu et qu'on ne casse rien.

- **Tests d'abonnement** :
  - On essaie d'ajouter un abonnement : ça doit marcher.
  - On essaie de l'enlever : ça doit marcher.
  - On essaie avec des utilisateurs qui n'existent pas : ça doit afficher une erreur (ce qui est bon signe !).
- **Tests d'analyse (Stats)** :
  - On lance la fonction `get_theme_stats()`.
  - On vérifie qu'elle trouve bien les thèmes "Technologie" et "Gaming" avec les bons chiffres, basés sur nos données de test.

## Comment lancer tout ça ?

Tout est automatique grâce à **Docker**.

1.  **Démarrer** : `docker-compose up -d` (Lance la base de données et installe tout).
2.  **Tester** :
    - `docker exec -i postgres_db psql -U admin -d scrollchain < tests/subscribe_tests.sql`
    - `docker exec -i postgres_db psql -U admin -d scrollchain < tests/theme_stats_tests.sql`
