-- Function: get_theme_stats
-- Description: Analyzes which themes generate the most interactions and determines the best performing visibility type for each.
-- Returns: Table (theme_name VARCHAR, total_interactions BIGINT, best_visibility Visibility)

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
