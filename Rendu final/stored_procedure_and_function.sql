-- Ulysse :
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

-- Thomas :

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

-- Erwan :

CREATE OR REPLACE FUNCTION get_posts_ordered_by_indirect_reach()
RETURNS TABLE(
    post_id INT,
    post_title VARCHAR,
    author_name VARCHAR,
    sharer_name VARCHAR,
    indirect_reach_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH ShareInteractions AS (
        -- Select all 'Share' interactions
        SELECT
            i.id_target_post,
            i.id_origin_user AS id_sharer
        FROM
            interaction i
        WHERE
            i.type_interaction = 'Share'
    ),
    PostAuthors AS (
        -- Get the author of each shared post
        SELECT
            p.id AS id_post,
            p.title,
            p.id_author,
            u.name_user AS author_name
        FROM
            post p
        JOIN
            user_ u ON p.id_author = u.id
    ),
    SharerFollowers AS (
        -- Get all followers of the sharers (Potential Indirect Audience)
        SELECT
            si.id_target_post,
            si.id_sharer,
            s.id_subscribed AS id_follower -- User who follows the sharer
        FROM
            ShareInteractions si
        JOIN
            subscribe s ON si.id_sharer = s.id_subscription -- s.id_subscription is the one being followed (the sharer)
    ),
    AuthorFollowers AS (
        -- Get all followers of the original authors (Direct Audience to exclude)
        SELECT
            pa.id_post,
            s.id_subscribed AS id_follower -- User who follows the author
        FROM
            PostAuthors pa
        JOIN
            subscribe s ON pa.id_author = s.id_subscription
    ),
    IndirectReach AS (
        -- Filter out followers who also follow the author
        SELECT
            sf.id_target_post,
            sf.id_sharer,
            sf.id_follower
        FROM
            SharerFollowers sf
        WHERE
            sf.id_follower NOT IN (
                SELECT af.id_follower
                FROM AuthorFollowers af
                WHERE af.id_post = sf.id_target_post
            )
            -- Also exclude the author themselves if they follow the sharer (optional, but logical)
            AND sf.id_follower != (SELECT id_author FROM post WHERE id = sf.id_target_post)
    )
    SELECT
        p.id_post AS post_id,
        p.title AS post_title,
        p.author_name AS author_name,
        u_sharer.name_user AS sharer_name,
        COUNT(DISTINCT ir.id_follower) AS indirect_reach_count
    FROM
        ShareInteractions si
    JOIN
        PostAuthors p ON si.id_target_post = p.id_post
    JOIN
        user_ u_sharer ON si.id_sharer = u_sharer.id
    LEFT JOIN
        IndirectReach ir ON si.id_target_post = ir.id_target_post AND si.id_sharer = ir.id_sharer
    GROUP BY
        p.id_post, p.title, p.author_name, u_sharer.name_user, si.id_sharer
    ORDER BY
        indirect_reach_count DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_subscribe(
    p_follower_id INT,
    p_target_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verify if the follower (search for subscribed) exists
    IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_follower_id) THEN
        RAISE EXCEPTION 'User (subscribed) with ID % does not exist', p_follower_id;
    END IF;

    -- Verify if the target (search for subscription) exists
    IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_target_id) THEN
        RAISE EXCEPTION 'User (subscription) with ID % does not exist', p_target_id;
    END IF;

    -- Insert the subscription
    INSERT INTO subscribe (id_subscribed, id_subscription)
    VALUES (p_follower_id, p_target_id);

    -- Verify insertion
    IF EXISTS (SELECT 1 FROM subscribe WHERE id_subscribed = p_follower_id AND id_subscription = p_target_id) THEN
        RAISE NOTICE 'Subscription successfully added.';
    ELSE
        RAISE EXCEPTION 'Failed to add subscription.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE remove_subscribe(
    p_follower_id INT,
    p_target_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verify if the follower (search for subscribed) exists
    IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_follower_id) THEN
        RAISE EXCEPTION 'User (subscribed) with ID % does not exist', p_follower_id;
    END IF;

    -- Verify if the target (search for subscription) exists
    IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_target_id) THEN
        RAISE EXCEPTION 'User (subscription) with ID % does not exist', p_target_id;
    END IF;

    -- Delete the subscription
    DELETE FROM subscribe
    WHERE id_subscribed = p_follower_id AND id_subscription = p_target_id;

    -- Verify deletion
    IF NOT EXISTS (SELECT 1 FROM subscribe WHERE id_subscribed = p_follower_id AND id_subscription = p_target_id) THEN
        RAISE NOTICE 'Subscription successfully removed.';
    ELSE
        RAISE EXCEPTION 'Failed to remove subscription.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_theme_stats()
RETURNS TABLE (
    theme_name VARCHAR,
    total_interactions BIGINT,
    best_visibility Visibility
) AS $$
BEGIN
    RETURN QUERY
    WITH ThemeCounts AS (
        -- Calculate total interactions per theme
        SELECT
            p.tag,
            COUNT(i.id_origin_user) AS total_count
        FROM post p
        JOIN interaction i ON p.id = i.id_target_post
        GROUP BY p.tag
    ),
    ThemeVisibilityCounts AS (
        -- Calculate interactions per theme AND visibility
        SELECT
            p.tag,
            p.visibility,
            COUNT(i.id_origin_user) AS vis_count,
            -- Rank them to find the top visibility per theme
            RANK() OVER (PARTITION BY p.tag ORDER BY COUNT(i.id_origin_user) DESC) as rnk
        FROM post p
        JOIN interaction i ON p.id = i.id_target_post
        GROUP BY p.tag, p.visibility
    )
    SELECT
        tc.tag,
        tc.total_count,
        tvc.visibility
    FROM ThemeCounts tc
    JOIN ThemeVisibilityCounts tvc ON tc.tag = tvc.tag
    WHERE tvc.rnk = 1
    ORDER BY tc.total_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Emmanuel :

CREATE OR REPLACE PROCEDURE interact_post(
    post_id INT,
	user_id INT,
	p_interaction_type InteractionType
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verify if the user already interact with this post with single time interaction
    IF EXISTS (SELECT 1 FROM interaction WHERE (p_interaction_type = 'like' OR p_interaction_type = 'share') AND p_interaction_type = type_interaction AND id_target_post = post_id AND id_origin_user = user_id) THEN
        RAISE EXCEPTION 'User with ID % have already % with post with ID %', user_id, p_interaction_type, post_id;
    END IF;

	-- Add the interaction
	INSERT INTO interaction (id_target_post, id_origin_user, type_interaction, interaction_date) VALUES (post_id, user_id, p_interaction_type, NOW());

END;
$$;

CREATE OR REPLACE VIEW subscription_view AS
SELECT u1.name_user "Utilisateur qui suit", u2.name_user "Utilisateur qui est suivi" FROM subscribe s JOIN user_ u1 ON s.id_subscribed  = u1.id JOIN user_ u2 ON s.id_subscription = u2.id;

CREATE OR REPLACE FUNCTION get_similar_users(p_target_user_id INT)
RETURNS TABLE (
    suggested_user_id INT,
    subscription_overlap_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH same_likings (user_id, common_tag_count) AS (
        SELECT
            likings.id AS user_id,
            count(likings.id) AS common_tag_count
        FROM likings
        WHERE likings.id != p_target_user_id
          AND tag IN (SELECT tag FROM likings WHERE likings.id = p_target_user_id)
        GROUP BY likings.id
    ),
    same_likings_users_subscription (sub_user_id) AS (
        SELECT id_subscription
        FROM subscribe
        JOIN (SELECT user_id FROM same_likings WHERE common_tag_count > 3) as slui
          ON user_id = id_subscribed
    )
    SELECT
        sub_user_id,
        count(sub_user_id)
    FROM same_likings_users_subscription
    GROUP BY sub_user_id
    HAVING count(sub_user_id) > 3
    ORDER BY sub_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_users_out_of_bound_interact()
RETURNS TABLE (
    user_id INT,
    out_of_bound_frequency FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH interactions_of_users_out_of_bound AS (
        SELECT
            u.id,
            count(*) AS nb_interaction
        FROM interaction i
        JOIN user_ u ON i.id_origin_user = u.id
        JOIN post p ON i.id_target_post = p.id
        WHERE p.id_author NOT IN (
            SELECT id_subscription
            FROM subscribe
            WHERE id_subscribed = u.id
        )
        GROUP BY u.id
    ),
    interactions_of_users AS (
        SELECT
            u.id,
            count(*) AS nb_interaction
        FROM user_ u
        JOIN interaction i ON u.id = i.id_origin_user
        GROUP BY u.id
    )
    SELECT
        i.id,
        out_i.nb_interaction::FLOAT / i.nb_interaction AS out_of_bound_frequency
    FROM interactions_of_users i
    JOIN interactions_of_users_out_of_bound out_i ON i.id = out_i.id ORDER BY out_of_bound_frequency DESC ;
END;
$$;

