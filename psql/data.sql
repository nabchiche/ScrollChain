-- Inserting Themes
INSERT INTO theme (tag) VALUES 
('Technology'),
('Art'),
('Gaming'),
('Travel'),
('Food'),
('Science'),
('Politics'),
('Health');

-- Inserting Users
INSERT INTO user_ (name_user, email, password, register_date, surname) VALUES
('Alice', 'alice@example.com', 'password123', '2023-01-15 10:00:00', 'Smith'),
('Bob', 'bob@example.com', 'password123', '2023-01-16 11:30:00', 'Johnson'),
('Charlie', 'charlie@example.com', 'password123', '2023-01-17 09:15:00', 'Brown'),
('David', 'david@example.com', 'password123', '2023-01-18 14:20:00', 'Wilson'),
('Eve', 'eve@example.com', 'password123', '2023-01-19 16:45:00', 'Davis'),
('Frank', 'frank@example.com', 'password123', '2023-01-20 08:00:00', 'Miller'),
('Grace', 'grace@example.com', 'password123', '2023-01-21 12:10:00', 'Taylor'),
('Heidi', 'heidi@example.com', 'password123', '2023-01-22 13:50:00', 'Anderson'),
('Ivan', 'ivan@example.com', 'password123', '2023-01-23 15:30:00', 'Thomas'),
('Judy', 'judy@example.com', 'password123', '2023-01-24 17:05:00', 'Jackson');

-- Inserting Groups
INSERT INTO group_ (name_group, tag) VALUES
('Tech Pioneers', 'Technology'),
('Digital Artists', 'Art'),
('Hardcore Gamers', 'Gaming'),
('World Travelers', 'Travel'),
('Gourmet Chefs', 'Food');

-- Inserting Likings (User interests)
INSERT INTO likings (id, tag) VALUES
(1, 'Technology'), (1, 'Science'),
(2, 'Art'), (2, 'Travel'),
(3, 'Gaming'), (3, 'Technology'),
(4, 'Travel'), (4, 'Food'),
(5, 'Food'), (5, 'Health');

-- Inserting Subscriptions (Followers)
INSERT INTO subscribe (id_subscribed, id_subscription) VALUES
(1, 2), (1, 3), -- Alice follows Bob and Charlie
(2, 1), -- Bob follows Alice
(3, 4), (3, 5), -- Charlie follows David and Eve
(4, 1), -- David follows Alice
(5, 2); -- Eve follows Bob

-- Inserting Memberships
INSERT INTO membership (id, name_group) VALUES
(1, 'Tech Pioneers'),
(2, 'Digital Artists'),
(3, 'Hardcore Gamers'),
(4, 'World Travelers'),
(5, 'Gourmet Chefs'),
(6, 'Tech Pioneers'),
(7, 'World Travelers');

-- Inserting Posts
INSERT INTO post (title, content, publish_date, visibility, tag, id_author) VALUES
('The Future of AI', 'Artificial Intelligence is evolving rapidly...', '2023-02-01 10:00:00', 'Public', 'Technology', 1),
('My Trip to Paris', 'Paris is beautiful in the spring...', '2023-02-02 11:00:00', 'Friends', 'Travel', 2),
('Review of Elden Ring', 'This game is a masterpiece...', '2023-02-03 12:00:00', 'Public', 'Gaming', 3),
('Best Pasta Recipe', 'Here is how you make authentic carbonara...', '2023-02-04 13:00:00', 'Subscribers', 'Food', 4),
('Modern Art Trends', 'Exploring minimalism in 2023...', '2023-02-05 14:00:00', 'Public', 'Art', 2),
('Quantum Computing', 'Introduction to qubits...', '2023-02-06 15:00:00', 'Public', 'Science', 1),
('Healthy Living Tips', 'Drink more water and sleep well...', '2023-02-07 16:00:00', 'Public', 'Health', 5),
('Political Climate', 'Discussing recent elections...', '2023-02-08 17:00:00', 'Private', 'Politics', 6),
('Space Exploration', 'Mars colonization plans...', '2023-02-09 18:00:00', 'Public', 'Science', 7),
('Vegan Diet Benefits', 'Why I switched to veganism...', '2023-02-10 19:00:00', 'Friends', 'Food', 8),
('VR Gaming', 'The state of Virtual Reality gaming...', '2023-02-11 20:00:00', 'Public', 'Gaming', 9),
('Solo Travel Guide', 'Tips for traveling alone...', '2023-02-12 21:00:00', 'Public', 'Travel', 10),
('Abstract Painting', 'My latest creation...', '2023-02-13 09:00:00', 'Subscribers', 'Art', 2),
('Blockchain Basics', 'Understanding crypto...', '2023-02-14 10:00:00', 'Public', 'Technology', 3),
('Italian Cuisine', 'Best pizza places in Naples...', '2023-02-15 11:00:00', 'Friends', 'Food', 4);

-- Inserting Interactions
INSERT INTO interaction (id_target_post, id_origin_user, type_interaction, interaction_date) VALUES
(1, 2, 'like', '2023-02-01 10:05:00'),
(1, 3, 'like', '2023-02-01 10:10:00'),
(2, 1, 'comment', '2023-02-02 11:15:00'),
(3, 4, 'like', '2023-02-03 12:20:00'),
(3, 5, 'share', '2023-02-03 12:25:00'),
(4, 3, 'like', '2023-02-04 13:30:00'),
(5, 1, 'like', '2023-02-05 14:35:00'),
(6, 2, 'like', '2023-02-06 15:40:00'),
(7, 3, 'comment', '2023-02-07 16:45:00'),
(8, 1, 'like', '2023-02-08 17:50:00');

-- Inserting Messages
INSERT INTO message (id_receiver, id_sender, content, send_date) VALUES
(2, 1, 'Hey Bob, how are you?', '2023-02-01 09:00:00'),
(1, 2, 'I am good Alice, thanks!', '2023-02-01 09:05:00'),
(3, 1, 'Did you see the news?', '2023-02-02 10:00:00'),
(4, 3, 'Let us play some games tonight', '2023-02-03 18:00:00'),
(5, 4, 'Recipe was great!', '2023-02-05 12:00:00');
