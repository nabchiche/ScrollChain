-- Test Script for Indirect Reach Function
-- Run this inside the container if possible, or just review the logic.

\echo '--------------------------------------'
\echo 'TEST: Setup and Verify get_posts_ordered_by_indirect_reach()'
\echo '--------------------------------------'

BEGIN; 

-- 1. Setup Test Data
-- Create unique users for this test to avoid conflicts
INSERT INTO user_ (name_user, email, password, register_date, surname) VALUES
('TestAuthor', 'author@test.com', 'pass', NOW(), 'A'),
('TestSharer', 'sharer@test.com', 'pass', NOW(), 'S'),
('TestIndirect1', 'indirect1@test.com', 'pass', NOW(), 'I1'), -- Follows Sharer ONLY
('TestIndirect2', 'indirect2@test.com', 'pass', NOW(), 'I2'), -- Follows Sharer AND Author
('TestDirectOnly', 'direct@test.com', 'pass', NOW(), 'D');   -- Follows Author ONLY

-- Capture IDs
DO $$
DECLARE
    id_author INT;
    id_sharer INT;
    id_i1 INT;
    id_i2 INT;
    id_d INT;
    id_post INT;
    rec RECORD;
    found_post BOOLEAN := FALSE;
BEGIN
    SELECT id INTO id_author FROM user_ WHERE email = 'author@test.com';
    SELECT id INTO id_sharer FROM user_ WHERE email = 'sharer@test.com';
    SELECT id INTO id_i1 FROM user_ WHERE email = 'indirect1@test.com';
    SELECT id INTO id_i2 FROM user_ WHERE email = 'indirect2@test.com';
    SELECT id INTO id_d FROM user_ WHERE email = 'direct@test.com';

    -- Create Post
    INSERT INTO post (title, content, publish_date, visibility, tag, id_author) VALUES
    ('Test Post Indirect Reach', 'Content', NOW(), 'Public', 'Technology', id_author)
    RETURNING id INTO id_post;

    -- Setup Subscriptions
    -- TestIndirect1 follows Sharer
    INSERT INTO subscribe (id_subscribed, id_subscription) VALUES (id_i1, id_sharer);
    
    -- TestIndirect2 follows Sharer AND Author
    INSERT INTO subscribe (id_subscribed, id_subscription) VALUES (id_i2, id_sharer);
    INSERT INTO subscribe (id_subscribed, id_subscription) VALUES (id_i2, id_author);

    -- TestDirectOnly follows Author
    INSERT INTO subscribe (id_subscribed, id_subscription) VALUES (id_d, id_author);

    -- Create Share Interaction
    INSERT INTO interaction (id_target_post, id_origin_user, type_interaction, interaction_date) VALUES
    (id_post, id_sharer, 'Share', NOW());

    -- 2. Verify Function Output
    FOR rec IN SELECT * FROM get_posts_ordered_by_indirect_reach() LOOP
        RAISE NOTICE 'Post: %, Sharer: %, Count: %', rec.post_title, rec.sharer_name, rec.indirect_reach_count;
        
        IF rec.post_id = id_post AND rec.sharer_name = 'TestSharer' THEN
            found_post := TRUE;
            IF rec.indirect_reach_count = 1 THEN
                RAISE NOTICE 'SUCCESS: Correct indirect reach count (1) for Test Post.';
            ELSE
                RAISE EXCEPTION 'FAILURE: Expected indirect reach count 1, got %', rec.indirect_reach_count;
            END IF;
        END IF;
    END LOOP;

    IF NOT found_post THEN
        RAISE EXCEPTION 'FAILURE: Test post not found in function output.';
    END IF;

END $$;

ROLLBACK; -- Clean up test data

\echo '--------------------------------------'
\echo 'TEST PARTIALLY COMPLETED (Data rolled back)'
\echo '--------------------------------------'
