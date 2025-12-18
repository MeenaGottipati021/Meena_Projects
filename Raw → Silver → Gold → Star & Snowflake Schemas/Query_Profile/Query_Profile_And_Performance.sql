--query profile
--but when we open the Query Profile, it just shows how Snowflake executed the query and read the data
--running this query returns the cached result, so it executes very fast.
SELECT *
FROM demo_gold.users_gold
WHERE id = 3;
-- Enable cache (default behavior)
ALTER SESSION SET USE_CACHED_RESULT = TRUE;

-- to check n number of times query profile
-- rerun
SELECT * FROM demo_gold.users_gold WHERE id = 3;
--When you turn the cache OFF, Snowflake reads the data again from storage on every run instead of using the previous cached result.
-- turn of cache
ALTER SESSION SET USE_CACHED_RESULT = FALSE;
-- to see data in id=1
SELECT *
FROM demo_gold.users_gold
WHERE id = 1;
--Query Profile can be used for any query in Snowflake, such as SELECT, INSERT, UPDATE, DELETE, or MERGE. It gives information about how Snowflake executed the query and helps analyze data scanning and performance.
