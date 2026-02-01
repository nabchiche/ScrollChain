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