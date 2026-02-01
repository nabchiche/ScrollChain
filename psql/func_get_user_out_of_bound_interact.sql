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