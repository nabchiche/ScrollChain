-- Test Script for Subscription Procedures
-- Run this inside the container: psql -U admin -d scrollchain < tests/subscribe_tests.sql

\echo '--------------------------------------'
\echo 'TEST 1: Add Subscription (Alice -> Eve)'
\echo '--------------------------------------'
DO $$
BEGIN
    -- Alice (1) follows Eve (5)
    CALL add_subscribe(1, 5);
    
    IF EXISTS (SELECT 1 FROM subscribe WHERE id_subscribed = 5 AND id_subscription = 1) THEN
        RAISE NOTICE 'SUCCESS: Subscription Alice -> Eve created.';
    ELSE
        RAISE EXCEPTION 'FAILURE: Subscription Alice -> Eve NOT found.';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'FAILURE: Error during creation: %', SQLERRM;
END;
$$;

\echo '--------------------------------------'
\echo 'TEST 2: Remove Subscription (Alice -> Eve)'
\echo '--------------------------------------'
DO $$
BEGIN
    -- Alice (1) unfollows Eve (5)
    CALL remove_subscribe(1, 5);
    
    IF NOT EXISTS (SELECT 1 FROM subscribe WHERE id_subscribed = 5 AND id_subscription = 1) THEN
        RAISE NOTICE 'SUCCESS: Subscription Alice -> Eve removed.';
    ELSE
        RAISE EXCEPTION 'FAILURE: Subscription Alice -> Eve still exists.';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'FAILURE: Error during removal: %', SQLERRM;
END;
$$;

\echo '--------------------------------------'
\echo 'TEST 3: Add Subscription with Invalid User (Follower 999)'
\echo '--------------------------------------'
DO $$
BEGIN
    -- User 999 (Does not exist) follows Alice (1)
    CALL add_subscribe(999, 1);
    RAISE EXCEPTION 'FAILURE: Procedure should have failed but did not.';
EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'User (subscription) with ID 999 does not exist%' THEN
        RAISE NOTICE 'SUCCESS: Detected invalid user as expected.';
    ELSE
        RAISE NOTICE 'FAILURE: Unexpected error message: %', SQLERRM;
    END IF;
END;
$$;

\echo '--------------------------------------'
\echo 'TEST 4: Remove Subscription with Invalid User (Target 999)'
\echo '--------------------------------------'
DO $$
BEGIN
    -- Alice (1) tries to unfollow User 999 (Does not exist)
    CALL remove_subscribe(1, 999);
    RAISE EXCEPTION 'FAILURE: Procedure should have failed but did not.';
EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'User (subscribed) with ID 999 does not exist%' THEN
        RAISE NOTICE 'SUCCESS: Detected invalid user as expected.';
    ELSE
        RAISE NOTICE 'FAILURE: Unexpected error message: %', SQLERRM;
    END IF;
END;
$$;

\echo '--------------------------------------'
\echo 'ALL TESTS COMPLETED'
\echo '--------------------------------------'
