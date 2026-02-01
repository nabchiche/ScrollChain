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
