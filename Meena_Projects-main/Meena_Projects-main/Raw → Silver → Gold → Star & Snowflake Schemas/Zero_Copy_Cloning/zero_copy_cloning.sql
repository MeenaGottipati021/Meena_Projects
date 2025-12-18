-- zero copy cloning
--creating a clone table This command creates a new table that looks like a copy of the original table, but it does not physically copy the data—it shares the same micro-partitions.
--demo_gold.users_gold_clone is the new clone table
CREATE TABLE demo_gold.users_gold_clone
CLONE demo_gold.users_gold;
--and demo_gold.users_gold is the original table being cloned.
--to see the new demo_gold.users_gold_clone clone table data 
SELECT *
FROM demo_gold.users_gold_clone
WHERE id = 1;

--inserting data into original table demo_gold.users_gold
INSERT INTO demo_gold.users_gold ( id, name, email, status, event_ts, hash_value, start_date, end_date, is_current, is_deleted ) VALUES ( 10, 'Test Clone', 'clone@test.com', 'ACTIVE', CURRENT_TIMESTAMP(), 'testhash', CURRENT_TIMESTAMP(), NULL, TRUE, FALSE );

-- To see result original table demo_gold.users_gold
SELECT *
FROM demo_gold.users_gold
WHERE id = 10;
-- To show the result into original clone table  table demo_gold.users_gold_clone
SELECT *
FROM demo_gold.users_gold_clone
WHERE id = 10;
