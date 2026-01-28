CREATE OR REPLACE PROCEDURE add_subscribe(
    p_follower_id INT,
    p_target_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verify if the follower (subscription) exists
    IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_follower_id) THEN
        RAISE EXCEPTION 'User (subscription) with ID % does not exist', p_follower_id;
    END IF;

    -- Verify if the target (subscribed) exists
    IF NOT EXISTS (SELECT 1 FROM user_ WHERE id = p_target_id) THEN
        RAISE EXCEPTION 'User (subscribed) with ID % does not exist', p_target_id;
    END IF;
    
    -- Insert the subscription
    INSERT INTO subscribe (id_subscribed, id_subscription)
    VALUES (p_target_id, p_follower_id);

    -- Verify insertion
    IF EXISTS (SELECT 1 FROM subscribe WHERE id_subscribed = p_target_id AND id_subscription = p_follower_id) THEN
        RAISE NOTICE 'Subscription successfully added.';
    ELSE
        RAISE EXCEPTION 'Failed to add subscription.';
    END IF;
END;
$$;