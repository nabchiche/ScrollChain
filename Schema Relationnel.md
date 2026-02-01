# Schéma Relationnel

![](./Projet%20de%20BDR.svg)

# Explications

#### Traduction des Associations

- Context : (1,1) ; (0,n) Devient une clé étrangère dans `post` **tag** vers `theme`

- Subject : (1,1) ; (0,n) Devient une clé étrangère dans `group_` **tag** vers `theme`

- Likings : (0,n) ; (0,n) Devient une table d'association à part entière contenant deux clés étrangères dans `likings` **id** vers `user_` et **tag** vers `theme`

- Membership : (0,n) ; (0,n) Devient une table d'association à part entière contenant deux clés étrangères dans `membership` **id** vers `user_` et **name** vers `group_`

- Author : (0,n) ; (1,1) Devient une clé étrangère dans `post` **author_id** vers `user_`

- Sender : (0,n) ; (1,1) Devient une clé étrangère dans `message` **sender_id** vers `user_`

- Receiver : (0,n) ; (1,1) Devient une clé étrangère dans `message` **receiver_id** vers `user_`

- Originate : (0,n) ; (1,1) Devient une clé étrangère dans `interaction` **id** vers `user_`

- Target : (0,n) ; (1,1) Devient une clé étrangère dans `interaction` **post_id** vers `post`

- Subscribe : (0,n) ; (0,n) Devient une table d'association réflexive contenant deux clés étrangères dans `subscribe` **subscriber_id** vers `user_` et **subscribed_to_id** vers `user_`

## Details des Clés

- `user_` : Simple id pour identifier l'utilisateur **<u>id</u>**

- `post` : Simple id pour identifier le post **<u>id</u>**

- `subscribe` : Clé primaire composée des deux utilisateurs impliqués dans clés étrangères, celui qui s'abonne et celui qui est suivi **<u>id_subscribed</u>**, **<u>id_subscription</u>**

- `theme` : Chaque thème est identifié de manière unique par son libellé **<u>tag</u>**

- `group_` : Le nom du groupe est unique et permet de l’identifier **<u>name</u>**

- `message` : Chaque message est identifié par un identifiant unique **<u>id</u>**

- `interaction` : Chaque interaction possède un identifiant unique **<u>id</u>**

- `membership` : Clé primaire composée de l’utilisateur et du groupe auquel il appartient **<u>id</u>**, **<u>name</u>**

- `likings` : Clé primaire composée de l’utilisateur et du thème qu’il aime **<u>id</u>**, **<u>tag</u>**




