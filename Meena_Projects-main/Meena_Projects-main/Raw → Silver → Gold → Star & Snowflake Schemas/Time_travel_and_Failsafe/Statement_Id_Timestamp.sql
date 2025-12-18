--Time travel concept
--To Check statement id querry
SELECT query_id, query_text, start_time
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
ORDER BY start_time DESC;

--inserting new one record 
INSERT INTO demo_raw.raw_users_json (raw_data)
SELECT PARSE_JSON('{
  "id": 5,
  "name": "Test User",
  "email": "test@gmail.com",
  "status": "DELETED",
  "event_ts": "2025-12-06 18:00:00"
}');
-- to see raw output 
SELECT
    raw_data:id::INT AS id,
    raw_data:name::STRING AS name,
    raw_data:email::STRING AS email,
    raw_data:status::STRING AS status,
    raw_data:event_ts::TIMESTAMP AS event_ts,
    load_ts
FROM demo_raw.raw_users_json
WHERE raw_data:id::INT = 5;
--Drop or delete the row first
DELETE FROM demo_raw.raw_users_json
WHERE raw_data:id::INT = 5;
-- it gives statement id
SELECT query_id, query_text, start_time
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE query_text ILIKE 'INSERT%'
  AND query_text ILIKE '%"id": 5%'
  AND start_time::DATE = CURRENT_DATE()
ORDER BY start_time DESC
LIMIT 1;
 --Recover using statement ID
SELECT *
FROM demo_raw.raw_users_json
AT (STATEMENT => '01c10e16-0004-162f-000a-53f6000b705a')
WHERE raw_data:id::INT = 5;
--Or re-insert it back into the table
INSERT INTO demo_raw.raw_users_json
SELECT *
FROM demo_raw.raw_users_json
AT (STATEMENT => '01c10e16-0004-162f-000a-53f6000b705a')
WHERE raw_data:id = 5;

--Time travel using operation time stamp
--step 1 to check time travel timestamp operation inserterting data 
INSERT INTO demo_raw.raw_users_json (raw_data)
SELECT PARSE_JSON('{
  "id": 99,
  "name": "Tomorrow Test",
  "email": "test99@gmail.com",
  "status": "ACTIVE",
  "event_ts": "2025-12-06 20:11:00"
}');
--STEP 2 — Check it is inserted
SELECT *
FROM demo_raw.raw_users_json
WHERE raw_data:id::INT = 99;
--STEP 3 — DELETE it
DELETE FROM demo_raw.raw_users_json
WHERE raw_data:id::INT = 99;
--STEP 4 — Find timestamp 
SELECT 
    query_id,
    query_text,
    start_time
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE query_text ILIKE '%"id": 99%'
ORDER BY start_time DESC
LIMIT 1;
-- step 5 this query gives the information about the deleted data using the timestamp.
SELECT *
FROM demo_raw.raw_users_json
AT (TIMESTAMP => '2025-12-07 10:52:26.275 -0800')
WHERE raw_data:id::INT = 99;
--To store the data back into the table
INSERT INTO demo_raw.raw_users_json
SELECT *
FROM demo_raw.raw_users_json
AT (TIMESTAMP => '2025-12-07 09:59:31.059 -0800')





  
WHERE raw_data:id::INT = 99;
