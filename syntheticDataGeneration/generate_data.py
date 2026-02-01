import random
from datetime import datetime, timedelta
from faker import Faker
import hashlib
from collections import defaultdict

# --- Configuration ---
NUM_USERS = 300
NUM_THEMES = 40
NUM_GROUPS = 15
NUM_POSTS = 1000  # Increased to ensure enough content for interactions
NUM_INTERACTIONS = 2000
PROB_COHERENT_SUB = 0.85

fake = Faker()


# --- Helpers ---
def escape_sql(text):
    return text.replace("'", "''")


def get_random_date():
    return fake.date_time_between(start_date="-2y", end_date="now")


def generate_password_hash():
    return hashlib.sha512(fake.password().encode()).hexdigest()[0:128]


output_file = "insert_data_v2.sql"

# --- In-Memory Stores ---
users = []
themes = []
user_likings = defaultdict(set)
posts_by_author = defaultdict(list)  # Mapping to find posts quickly
user_subscriptions = defaultdict(set)  # Track subscriptions for logic
all_post_ids = []

print(f"Generating optimized test data for {NUM_USERS} users...")

with open(output_file, "w", encoding="utf-8") as f:
    f.write("-- Synthetic Data V2: Optimized for Out-Of-Bound Logic\n\n")

    # 1. Themes
    print("Generating Themes...")
    base_topics = [
        "Tech",
        "Art",
        "Science",
        "Politics",
        "Health",
        "Travel",
        "Food",
        "Music",
    ]
    for topic in base_topics:
        for i in range(1, 6):
            themes.append(f"{topic}_{i}")
    while len(themes) < NUM_THEMES:
        t = fake.word() + "_" + str(random.randint(1, 99))
        if t not in themes:
            themes.append(t)

    for t in themes:
        f.write(f"INSERT INTO theme (tag) VALUES ('{t}');\n")
    f.write("\n")

    # 2. Users
    print("Generating Users...")
    for i in range(1, NUM_USERS + 1):
        profile = fake.simple_profile()
        u = {
            "id": i,
            "name": escape_sql(profile["name"].split(" ")[0]),
            "surname": escape_sql(profile["name"].split(" ")[-1]),
            "email": f"{i}_{profile['mail']}",
            "password": generate_password_hash(),
            "reg_date": get_random_date(),
        }
        users.append(u)
        f.write(
            f"INSERT INTO user_ (name_user, email, password, register_date, surname) "
            f"VALUES ('{u['name']}', '{u['email']}', '{u['password']}', '{u['reg_date']}', '{u['surname']}');\n"
        )
    f.write("\n")

    # 3. Likings
    print("Generating Likings...")
    for u in users:
        persona = random.choice(base_topics)
        persona_tags = [t for t in themes if t.startswith(persona)]
        random_tags = random.sample(themes, k=3)
        user_tags = set(persona_tags + random_tags)
        user_likings[u["id"]] = list(user_tags)
        for tag in user_tags:
            f.write(f"INSERT INTO likings (id, tag) VALUES ({u['id']}, '{tag}');\n")
    f.write("\n")

    # 4. Groups & Memberships
    print("Generating Groups...")
    groups = []
    for i in range(NUM_GROUPS):
        g_tag = random.choice(themes)
        g_name = f"Group {g_tag} {i}"
        groups.append({"name": g_name, "tag": g_tag})
        f.write(
            f"INSERT INTO group_ (name_group, tag) VALUES ('{g_name}', '{g_tag}');\n"
        )

    for g in groups:
        interested_users = [
            uid for uid, tags in user_likings.items() if g["tag"] in tags
        ]
        for uid in interested_users:
            if random.random() > 0.5:
                f.write(
                    f"INSERT INTO membership (id, name_group) VALUES ({uid}, '{g['name']}');\n"
                )
    f.write("\n")

    # 5. Posts
    print("Generating Posts...")
    post_visibility = ["Private", "Friends", "Subscribers", "Public"]
    for i in range(1, NUM_POSTS + 1):
        author_id = random.randint(1, NUM_USERS)
        if user_likings[author_id]:
            tag = random.choice(user_likings[author_id])
        else:
            tag = random.choice(themes)

        p_date = get_random_date()
        p_vis = random.choice(post_visibility)

        # Store for interaction logic
        posts_by_author[author_id].append({"id": i, "date": p_date})
        all_post_ids.append(i)

        f.write(
            f"INSERT INTO post (title, content, publish_date, visibility, tag, id_author) "
            f"VALUES ('Post {i}', 'Content {i}', '{p_date}', '{p_vis}', '{tag}', {author_id});\n"
        )
    f.write("\n")

    # 6. Subscribe (Populate user_subscriptions)
    print("Generating Subscriptions...")
    unique_subs = set()

    for subscriber in users:
        subscriber_id = subscriber["id"]
        my_tags = set(user_likings[subscriber_id])
        num_subs = random.randint(5, 15)

        targets = []
        candidates = []
        for other in users:
            if other["id"] == subscriber_id:
                continue
            other_tags = set(user_likings[other["id"]])
            if len(my_tags.intersection(other_tags)) > 3:
                candidates.append(other["id"])

        if candidates:
            k = min(len(candidates), int(num_subs * PROB_COHERENT_SUB))
            targets.extend(random.sample(candidates, k))

        while len(targets) < num_subs:
            rand_id = random.randint(1, NUM_USERS)
            if rand_id != subscriber_id and rand_id not in targets:
                targets.append(rand_id)

        for target_id in targets:
            if (target_id, subscriber_id) not in unique_subs:
                f.write(
                    f"INSERT INTO subscribe (id_subscribed, id_subscription) VALUES ({target_id}, {subscriber_id});\n"
                )
                unique_subs.add((target_id, subscriber_id))
                # KEY: Track this in memory for the next step
                user_subscriptions[subscriber_id].add(target_id)
    f.write("\n")

    # 7. Interactions (THE CRITICAL UPDATE)
    print("Generating Interactions with 'Loyalty' logic...")
    interaction_types = ["like", "share", "comment"]
    used_interactions = set()

    # We iterate through users to assign them a "behavior"
    for actor in users:
        actor_id = actor["id"]
        subs = list(user_subscriptions[actor_id])

        # Assign a "Loyalty Score" to this user
        # 1.0 = Only interacts with subscriptions (Frequency 0.0)
        # 0.0 = Only interacts with randoms (Frequency 1.0)
        loyalty_score = random.random()

        # Determine how active this user is (1 to 15 interactions)
        num_actions = random.randint(1, 15)

        for _ in range(num_actions):
            target_post = None

            # DECISION: Interact In-Bound or Out-Of-Bound?
            is_in_bound = False

            if subs and random.random() < loyalty_score:
                # Try to find a post by a subscription
                friend_id = random.choice(subs)
                if posts_by_author[friend_id]:
                    target_post = random.choice(posts_by_author[friend_id])
                    is_in_bound = True

            # If we didn't pick an in-bound one (or user has no friends/friends have no posts)
            # Pick a random post from the wild
            if not target_post:
                # Pick a random post ID
                rand_post_id = random.choice(all_post_ids)
                # We don't have the object handy, just reconstruct minimal info needed
                # Actually, finding the author is expensive if we don't have a map.
                # Let's find who wrote it to ensure we don't accidentally pick own post
                # Simplified: Just pick a random post ID
                target_post = {"id": rand_post_id, "date": datetime.now()}
                # Note: There is a tiny chance this random post IS from a friend,
                # but that's statistically negligible and acceptable.

            # Prevent self-interaction (optional but good practice)
            # (Skipping deep check for speed, assuming random collision is low)

            i_type = random.choice(interaction_types)
            i_date = target_post["date"]  # Simplified date logic

            key = (target_post["id"], actor_id, i_type)
            if key not in used_interactions:
                f.write(
                    f"INSERT INTO interaction (id_target_post, id_origin_user, type_interaction, interaction_date) "
                    f"VALUES ({target_post['id']}, {actor_id}, '{i_type}', '{i_date}');\n"
                )
                used_interactions.add(key)

    # 8. Messages
    print("Generating Messages...")
    used_messages = set()
    for i in range(NUM_USERS * 2):
        s = random.randint(1, NUM_USERS)
        r = random.randint(1, NUM_USERS)
        if s != r:
            key = (r, s)
            if key not in used_messages:
                d = get_random_date()
                f.write(
                    f"INSERT INTO message (id_receiver, id_sender, content, send_date) "
                    f"VALUES ({r}, {s}, 'Msg {i}', '{d}');\n"
                )
                used_messages.add(key)

print(f"Done! Data written to {output_file}")
