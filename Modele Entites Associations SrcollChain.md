# Modèle Entités Associations

![EA_ScrollChain_bg_remove.png](/home/emmanuel-vermorel/Documents/EA_ScrollChain_bg_remove.png)

# Justification Cardinalités

- **Subscribe** : Un utilisateur peut s'abonner à plusieurs autres et plusieurs utilisateur peuvent s'abonner au même utilisateur.

- **Sender** : Un utilisateur peut envoyer plusieurs messages et un message n'a qu'un seul expéditeur.

- **Receiver** : Un utilisateur peut recevoir plusieurs messages et un message n'a qu'un seul destinataire.

- **Author** : Un utilisateur peut être auteur de plusieurs publications et une publication à un seul auteur.

- **Membership** : Un utilisateur peut être membre plusieurs groupe et un groupe peut avoir plusieurs membre.

- **Subject** : Un groupe est lié à un seul thème et un thème peut ne pas avoir de groupe associé ou bien un seul groupe associé.

- **Likings** : Un utilisateur peut apprécier plusieurs thème et un thème peut être apprécier par plusieurs utilisateurs.

- **Target** : Une publications peut être la cible de plusieurs interactions et une interaction ne cible qu'une publication.  

- **Originate** : Un utilisateur peut être à l'origine de plusieurs interaction et une interaction n'est originaire que d'un seul utilisateur.


