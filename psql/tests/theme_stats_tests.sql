-- Test Script for Theme Stats Function
-- Run this inside the container: psql -U admin -d scrollchain < tests/theme_stats_tests.sql

\echo '--------------------------------------'
\echo 'TEST: Verify get_theme_stats() output'
\echo '--------------------------------------'
DO $$
DECLARE
    rec RECORD;
    found_tech BOOLEAN := FALSE;
    found_gaming BOOLEAN := FALSE;
BEGIN
    -- Loop through the results
    FOR rec IN SELECT * FROM get_theme_stats() LOOP
        RAISE NOTICE 'Theme: %, Interactions: %, Best Visibility: %', rec.theme_name, rec.total_interactions, rec.best_visibility;
        
        -- Check specific known data points from data.sql
        IF rec.theme_name = 'Technology' AND rec.total_interactions >= 2 AND rec.best_visibility = 'Public' THEN
            found_tech := TRUE;
        END IF;
        
        IF rec.theme_name = 'Gaming' AND rec.total_interactions >= 2 AND rec.best_visibility = 'Public' THEN
            found_gaming := TRUE;
        END IF;
    END LOOP;

    -- Verify expectations
    IF found_tech THEN
        RAISE NOTICE 'SUCCESS: Found Technology with expected stats.';
    ELSE
        RAISE EXCEPTION 'FAILURE: Technology theme stats not matching expectations.';
    END IF;

    IF found_gaming THEN
        RAISE NOTICE 'SUCCESS: Found Gaming with expected stats.';
    ELSE
        RAISE EXCEPTION 'FAILURE: Gaming theme stats not matching expectations.';
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'FAILURE: Error details: %', SQLERRM;
END;
$$;

\echo '--------------------------------------'
\echo 'TESTS COMPLETED'
\echo '--------------------------------------'
