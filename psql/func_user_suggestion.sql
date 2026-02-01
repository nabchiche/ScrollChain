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
        JOIN (SELECT user_id FROM same_likings WHERE common_tag_count > 3) 
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