-- Function to find publications that maximized their reach via indirect shares
-- "Indirect Reach" is defined as: Users who follow the sharer but DO NOT follow the original author.

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
        p.id AS post_id,
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
        p.id, p.title, p.author_name, u_sharer.name_user, si.id_sharer
    ORDER BY 
        indirect_reach_count DESC;
END;
$$ LANGUAGE plpgsql;
