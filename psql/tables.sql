CREATE TYPE Visibility AS ENUM ('Private', 'Friends', 'Subscribers', 'Public');

CREATE TABLE user_(
   id SERIAL,
   name_user VARCHAR(100) NOT NULL,
   email VARCHAR(200) NOT NULL,
   password CHAR(128) NOT NULL,
   register_date TIMESTAMP NOT NULL,
   surname VARCHAR(100) NOT NULL,
   PRIMARY KEY(id),
   UNIQUE(email)
);

CREATE TABLE message(
   id_receiver INT,
   id_sender INT,
   content TEXT NOT NULL,
   send_date TIMESTAMP,
   PRIMARY KEY(id_receiver, id_sender, send_date),
   FOREIGN KEY(id_receiver) REFERENCES user_(id),
   FOREIGN KEY(id_sender) REFERENCES user_(id)
);

CREATE TABLE theme(
   tag VARCHAR(144),
   PRIMARY KEY(tag)
);

CREATE TABLE post(
   id SERIAL,
   title VARCHAR(144) NOT NULL,
   content TEXT NOT NULL,
   publish_date TIMESTAMP NOT NULL,
   visibility Visibility NOT NULL,
   tag VARCHAR(144) NOT NULL,
   id_author INT NOT NULL,
   PRIMARY KEY(id),
   FOREIGN KEY(tag) REFERENCES theme(tag),
   FOREIGN KEY(id_author) REFERENCES user_(id)
);

CREATE TABLE group_(
   name_group VARCHAR(144),
   tag VARCHAR(144) NOT NULL,
   PRIMARY KEY(name_group),
   FOREIGN KEY(tag) REFERENCES theme(tag)
);

CREATE TABLE interaction(
   id_target_post INT,
   id_origin_user INT,
   type_interaction VARCHAR(50),
   interaction_date TIMESTAMP NOT NULL,
   PRIMARY KEY(id_target_post, id_origin_user, type_interaction),
   FOREIGN KEY(id_target_post) REFERENCES post(id),
   FOREIGN KEY(id_origin_user) REFERENCES user_(id)
);

CREATE TABLE subscribe(
   id_subscribed INT,
   id_subscription INT,
   PRIMARY KEY(id_subscribed, id_subscription),
   FOREIGN KEY(id_subscribed) REFERENCES user_(id),
   FOREIGN KEY(id_subscription) REFERENCES user_(id)
);

CREATE TABLE membership(
   id SERIAL,
   name_group VARCHAR(144),
   PRIMARY KEY(id, name_group),
   FOREIGN KEY(id) REFERENCES user_(id),
   FOREIGN KEY(name_group) REFERENCES group_(name_group)
);

CREATE TABLE likings(
   id SERIAL,
   tag VARCHAR(144),
   PRIMARY KEY(id, tag),
   FOREIGN KEY(id) REFERENCES user_(id),
   FOREIGN KEY(tag) REFERENCES theme(tag)
);
