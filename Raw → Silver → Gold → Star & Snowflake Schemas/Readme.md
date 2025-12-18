End-to-End Snowflake Data Pipeline RAW–SILVER–GOLD | SCD-2 | Time Travel | Fail-safe | Views | Materialized Views | Query Profile | Zero-Copy Cloning


1\.Database Creation:\
1\.a Creating Database demo\_project\
This query creates a new database named demo_project if it doesn’t already exist. It ensures that the database is available for storing tables and data without throwing an error if it already exists.
Query:
CREATE DATABASE IF NOT EXISTS demo\_project;

OutPut:
![Database_Creation.](Images/Database_Creation.png)\
1\.b Here, we are telling to use the database demo\_project
This query selects the demo_project database so that any subsequent commands (like creating tables or inserting data) will be executed in this database.
Query:
USE DATABASE demo\_project;\
Output:
![Use_Database.](Images/Use_Database.png)

1\.c Creating Schema demo\_raw\
This query creates a new schema named demo_raw within the current database if it doesn’t already exist. A schema is like a folder inside the database that helps organize tables and other database objects.
Query:
CREATE SCHEMA IF NOT EXISTS demo\_raw;\
Output:
![Schema_Creation.](Images/Schema_Creation.png)

2\.RAW\_USERS\_JSON CREATION:
This query creates a table raw_users_json inside the demo_raw schema.

raw_data VARIANT: Stores JSON or semi-structured data.

load_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(): Automatically records the time when each row is inserted.

This table is used to store raw JSON data as it is loaded into the database.

Query:
CREATE OR REPLACE TABLE demo\_raw.raw\_users\_json (\
raw\_data VARIANT,                               \
load\_ts TIMESTAMP DEFAULT CURRENT\_TIMESTAMP()   

);

![Raw_users_json_creation.](Images/Raw_users_json_creation.png)

3\.Inserting\_Data:
These queries insert raw JSON data into the raw_users_json table.

PARSE_JSON(...) converts the text into JSON format that can be stored in the raw_data column.

Each row represents a user record with fields like id, name, email, status, and event_ts.

This step is used to load sample or raw user data into the database for further processing.

Queries:
INSERT INTO demo\_raw.raw\_users\_json (raw\_data)\
SELECT PARSE\_JSON('{\
"id": 1,\
"name": "Meena",\
"email": "Meena@gmail.com",\
"status": "ACTIVE",\
"event\_ts": "2025-11-27 11:39:00"\
}');

INSERT INTO demo\_raw.raw\_users\_json (raw\_data)

SELECT PARSE\_JSON('{\
"id": 2,\
"name": "priya",\
"email": "priya@gmail.com",\
"status": "ACTIVE",\
"event\_ts": "2025-11-27 11:40:00"\
}');

INSERT INTO demo\_raw.raw\_users\_json (raw\_data)\
SELECT PARSE\_JSON('{\
"id": 4,\
"name": "MG",\
"email": "meenag9@gmail.com",\
"status": "ACTIVE",\
"event\_ts": "2025-11-27 11:40:00"\
}');\

![Inserting_Data.](Images/Inserting_Data.png)\

To check the Data, we use a query 
Query:
SELECT \* FROM demo\_raw.raw\_users\_json;\
Output:
![raw_data_output.](Images/raw_data_output.png)\
Checking only 5 rows of data , But here we inserted only 3 rows.

![Img-1.](Images/Img-1.png)

SILVER LAYER:

Creating Schema demo\_silver\
This query creates a new schema named demo_silver within the current database if it doesn’t already exist.

This schema is typically used to store cleaned or transformed data after processing the raw data from demo_raw.
Query:
CREATE SCHEMA IF NOT EXISTS demo\_silver;\
![demo_silver_schema_creation.](Images/demo_silver_schema_creation.png)

Users\_Silver Table Creation:
This query creates a table users_silver inside the demo_silver schema.

Columns like id, name, email, status, and event_ts store structured and cleaned user data.

This table is used to store processed data extracted from the raw JSON data in raw_users_json.

Query:
CREATE OR REPLACE TABLE demo\_silver.users\_silver (\
id INT,\
name STRING,\
email STRING,\
status STRING,\
event\_ts TIMESTAMP\
);

![Users_Silver_Table Creation_Img1.](Images/Users_Silver_Table Creation_Img1.png)

OR

CREATE OR REPLACE TABLE demo\_silver.users\_silver AS\
SELECT\
id,\
name,\
email,\
status,\
event\_ts\
FROM (\
SELECT\
raw\_data:id::INT AS id,\
raw\_data:name::STRING AS name,\
raw\_data:email::STRING AS email,\
raw\_data:status::STRING AS status,\
raw\_data:event\_ts::TIMESTAMP AS event\_ts,\
ROW\_NUMBER() OVER (\
PARTITION BY raw\_data:id::INT\
ORDER BY raw\_data:event\_ts::TIMESTAMP DESC\
) AS rn\
FROM demo\_raw.raw\_users\_json\
)\
WHERE rn = 1\
ORDER BY id;

![Users_Silver_Table_Creation_Img2.](Images/Users_Silver_Table_Creation_Img2.png)

To check the data we use the query
This query retrieves all data from the users_silver table and sorts it by the id column.

It is used to view and verify the cleaned/processed user data stored in the silver table.
Query:
SELECT \* FROM demo\_silver.users\_silver ORDER BY id;

![Silverlayer_Data_Output.](Images/Silverlayer_Data_Output.png)

\

GOLD LAYER:\
Demo\_Gold Schema Successfully Created
This query creates a new schema named demo_gold within the current database if it doesn’t already exist.

The demo_gold schema is typically used to store final, aggregated, or business-ready data derived from the silver (cleaned) data.

Query:
CREATE SCHEMA IF NOT EXISTS demo\_gold;\
OutPut:
![Demo_Gold_Schema.](Images/Demo_Gold_Schema.png)

Table Creation for USERS\_GOLD
This query creates a table users_gold inside the demo_gold schema.

Columns like id, name, email, status, and event_ts store user information.

Additional columns (hash_value, start_date, end_date, is_current, is_deleted) are used for tracking changes, managing historical data, and handling Slowly Changing Dimensions (SCD).

This table is used to store the final, business-ready version of the user data.
Query:
CREATE OR REPLACE TABLE demo\_gold.users\_gold (\
` `id INT,\
` `name STRING,\
` `email STRING,\
` `status STRING,\
` `event\_ts TIMESTAMP,\
` `hash\_value STRING,\
` `start\_date TIMESTAMP,\
` `end\_date TIMESTAMP,\
` `is\_current BOOLEAN,\
` `is\_deleted BOOLEAN

);

![Goldlayer_table_creation.](Images/Goldlayer_table_creation.png)

This query keeps the users\_gold table up to date by closing old user records and inserting new ones whenever user data changes, following a Slowly Changing Dimension (Type 2) pattern.

Query:

MERGE INTO demo\_gold.users\_gold g\
USING (\
SELECT\
id,\
name,\
email,\
status,\
event\_ts,\
`         `SHA2(CONCAT(id, name, email, status)) AS hash\_value\
`  `FROM demo\_silver.users\_silver\
) s

ON g.id = s.id AND g.is\_current = TRUE\
WHEN MATCHED THEN\
UPDATE SET

`        `g.end\_date   = s.event\_ts,

`        `g.is\_current = FALSE,\
`       `g.is\_deleted = (s.status = 'DELETED')

WHEN NOT MATCHED THEN\
` `INSERT (\
`         `id, name, email, status, event\_ts, hash\_value,\
`         `start\_date, end\_date, is\_current, is\_deleted

`    `)

`    `VALUES (\
`          `s.id, s.name, s.email, s.status, s.event\_ts, s.hash\_value,\
`          `s.event\_ts, NULL, TRUE, FALSE

`    `);

![SCD Type 2.](Images/SCD Type 2.png)\
To see the users\_gold Output we use the query\
SELECT\
`     `id,\
`    `name,\
`    `email,\
`    `status,\
`    `event\_ts,\
`    `hash\_value,\
`    `start\_date,\
`    `end\_date,\
`    `is\_current,\
`    `is\_deleted\
FROM demo\_gold.users\_gold\
ORDER BY id, start\_date;

\
![Users_Gold_Output.](Images/Users_Gold_Output.png)

STAR SCHEMA:\
\-------------------\
-- STAR Schema

So, basically, in the STAR schema, I design a denormalized model with a central fact table and surrounding dimension tables derived from the GOLD layer. This structure simplifies joins, improves query performance, and is optimized for reporting and BI workloads. The STAR schema is refreshed in a controlled and re-runnable manner to maintain consistency.

Star Schema Creation with the name demo\_star
This query creates a new schema named demo_star within the current database if it doesn’t already exist.

The demo_star schema is typically used to store fact and dimension tables for building a star schema, which is helpful for analytics and reporting.
Query:
CREATE SCHEMA IF NOT EXISTS demo\_star;
![demo_silver_schema_creation.](Images/demo_silver_schema_creation.png)

Table DIM\_USER Creation

CREATE OR REPLACE TABLE demo\_star.dim\_user (

`    `user\_sk INT AUTOINCREMENT,\
`    `id INT,\
`    `name STRING,\
`    `email STRING,\
`    `status STRING,\
`    `start\_date TIMESTAMP,\
`    `end\_date TIMESTAMP,\
`    `is\_current BOOLEAN,\
`    `is\_deleted BOOLEAN,\
`    `PRIMARY KEY (user\_sk)

);

![DIM_User_Creation.](Images/DIM_User_Creation.png)

Inserting the Data

INSERT INTO demo\_star.dim\_user

(\
id,\
name,\
email,\
status,\
start\_date,\
end\_date,\
is\_current,\
is\_deleted

)

SELECT\
id,\
name,\
email,\
status,\
start\_date,\
end\_date,\
is\_current,\
is\_deleted\
FROM demo\_gold.users\_gold;

![Inserting_DIM_User_Data.](Images/Inserting_DIM_User_Data.png)

FACT\_USER\_ACTIVITY:\
Fact\_User\_Activity table creation
This query creates a fact table fact_user_activity inside the demo_star schema.

fact_sk INT AUTOINCREMENT: Unique key for each record in the fact table.

user_sk INT: Foreign key linking to the user dimension table.

event_ts TIMESTAMP and status STRING: Store activity details.

This table is used to record user activities as facts for analytics in a star schema.

Query:
CREATE OR REPLACE TABLE demo\_star.fact\_user\_activity (\
fact\_sk INT AUTOINCREMENT,\
user\_sk INT,\
event\_ts TIMESTAMP,\
status STRING\
);

![Fact_table_creation.](Images/Fact_table_creation.png)

Data Inserting in Fact\_User\_Activity

INSERT INTO demo\_star.fact\_user\_activity (\
user\_sk,\
event\_ts,\
status\
)

SELECT\
d.user\_sk,\
g.event\_ts,\
g.status\
FROM demo\_gold.users\_gold g\
JOIN demo\_star.dim\_user d\
ON g.id = d.id;

![Fact_table_datainsertion.](Images/Fact_table_datainsertion.png)

Dimension table:

This query retrieves all data from the dim_user table in the demo_star schema and sorts it by user_sk.

It is used to view and verify user dimension data in the star schema for analytics.

SELECT \* FROM demo\_star.dim\_user ORDER BY user\_sk;\
\
![Dimension_output.](Images/Dimension_output.png)

Fact\_Table:
This query retrieves all data from the fact_user_activity table in the demo_star schema and sorts it by fact_sk.

It is used to view and verify the recorded user activity facts in the star schema for analytics.
Query: 
SELECT \* FROM demo\_star.fact\_user\_activity ORDER BY fact\_sk;

![Fact_output.](Images/Fact_output.png)

Full STAR SCHEMA JOIN:

SELECT\
f.fact\_sk,\
f.user\_sk,\
d.id,\
d.name,\
d.email,\
f.event\_ts,\
f.status,\
d.start\_date,\
d.end\_date,\
d.is\_current,\
d.is\_deleted\
FROM demo\_star.fact\_user\_activity f\
JOIN demo\_star.dim\_user d\
` `ON f.user\_sk = d.user\_sk

ORDER BY f.fact\_sk;

![Full_StarSchema_Join.](Images/Full_StarSchema_Join.png)

--SNOWFLAKE SCHEMA:

-- Snowflake Schema

So, basically, the Snowflake schema further normalizes the STAR schema by splitting dimensions into sub-dimensions such as name, email, and status. This reduces data redundancy and improves dimension maintainability while still supporting analytical queries. It demonstrates advanced dimensional modeling aligned with enterprise data warehouse standards.
This query creates a new schema named demo_snowflake within the current database if it doesn’t already exist.

The demo_snowflake schema is typically used to store fact and dimension tables in a snowflake schema, which is a normalized form of the star schema for analytics and reporting.

Query:

CREATE SCHEMA IF NOT EXISTS demo\_snowflake;

![Demo_Snowflake_schema.](Images/Demo_Snowflake_schema.png)

3 tables created: name, email, status

CREATE OR REPLACE TABLE demo\_snowflake.dim\_name (\
name\_sk INT AUTOINCREMENT,\
name STRING,\
PRIMARY KEY (name\_sk)\
);

CREATE OR REPLACE TABLE demo\_snowflake.dim\_email (\
email\_sk INT AUTOINCREMENT,

`    `email STRING,\
`    `PRIMARY KEY (email\_sk)\
);

CREATE OR REPLACE TABLE demo\_snowflake.dim\_status (\
status\_sk INT AUTOINCREMENT,\
status STRING,\
PRIMARY KEY (status\_sk)\
);

![Tables_Creation.](Images/Tables_Creation.png)

Inserting Data in Snowflake

INSERT INTO demo\_snowflake.dim\_name (name)\
SELECT DISTINCT name FROM demo\_gold.users\_gold;

INSERT INTO demo\_snowflake.dim\_email (email)\
SELECT DISTINCT email FROM demo\_gold.users\_gold;

INSERT INTO demo\_snowflake.dim\_status (status)\
SELECT DISTINCT status FROM demo\_gold.users\_gold;

![Inserting_Data_Snowflake.](Images/Inserting_Data_Snowflake.png)

Name\_sk data:

SELECT \* FROM demo\_snowflake.dim\_name ORDER BY name\_sk;

![name_sk.](Images/name_sk.png)

Email\_sk data:

SELECT \* FROM demo\_snowflake.dim\_email ORDER BY email\_sk;

![email_sk.](Images/email_sk.png)

Status\_sk data:

SELECT \* FROM demo\_snowflake.dim\_status ORDER BY status\_sk;

![status_sk.](Images/status_sk.png)

\
Snowflake\_Schema\_DIM\_USER\_Tablecreation

This query creates a dimension table dim_user inside the demo_snowflake schema.

user_sk INT AUTOINCREMENT: Unique key for each user.

id, name_sk, email_sk, status_sk: Store references to detailed user information (normalized).

start_date, end_date, is_current, is_deleted: Track historical changes for Slowly Changing Dimensions (SCD).

PRIMARY KEY (user_sk): Ensures each user record is unique.

This table is used to store normalized user data for a snowflake schema.

Query:

CREATE OR REPLACE TABLE demo\_snowflake.dim\_user (\
user\_sk INT AUTOINCREMENT,\
id INT,\
name\_sk INT,\
email\_sk INT,\
status\_sk INT,\
start\_date TIMESTAMP,\
end\_date TIMESTAMP,\
is\_current BOOLEAN,\
is\_deleted BOOLEAN,\
PRIMARY KEY (user\_sk)

);

![DIM_User_Creation.](Images/DIM_User_Creation.png)

Inserting data in DIM\_USER Snowflake\_Schema

INSERT INTO demo\_snowflake.dim\_user (\
id, name\_sk, email\_sk, status\_sk,\
start\_date, end\_date, is\_current, is\_deleted

)

SELECT\
g.id,\
n.name\_sk,\
e.email\_sk,\
s.status\_sk,\
g.start\_date,\
g.end\_date,\
g.is\_current,\
g.is\_deleted

FROM demo\_gold.users\_gold g\
JOIN demo\_snowflake.dim\_name n     ON g.name  = n.name\
JOIN demo\_snowflake.dim\_email e    ON g.email = e.email\
JOIN demo\_snowflake.dim\_status s   ON g.status = s.status;

![Insertingdata_dimuser_snowflake.](Images/Insertingdata_dimuser_snowflake.png)

DIMUSER\_VIEW:

SELECT \* FROM demo\_snowflake.dim\_user ORDER BY user\_sk;

![DIMUSER_VIEW.](Images/DIMUSER_VIEW.png)

Snowflake\_fact\_user\_activity table creation:

CREATE OR REPLACE TABLE demo\_snowflake.fact\_user\_activity (

`    `fact\_sk INT AUTOINCREMENT,\
`    `user\_sk INT,\
`    `event\_ts TIMESTAMP,\
`    `status\_sk INT

);

![Snowflake schema_fact_table_creation.](Images/Snowflake schema_fact_table_creation.png)

Inserting data in the snowflake schema fact\_user\_activity table.

INSERT INTO demo\_snowflake.fact\_user\_activity (\
user\_sk, event\_ts, status\_sk\
)\
SELECT\
du.user\_sk,\
g.event\_ts,\
st.status\_sk\
FROM demo\_gold.users\_gold g

JOIN demo\_snowflake.dim\_user du   ON g.id = du.id\
JOIN demo\_snowflake.dim\_status st ON g.status = st.status;

![Insertingdata_dimuser_snowflake.](Images/Insertingdata_dimuser_snowflake.png)

To see the fact table data ORDER BY fact\_sk

SELECT \* FROM demo\_snowflake.fact\_user\_activity ORDER BY fact\_sk;

![SS_ORDERBY fact_sk.](Images/SS_ORDERBY fact_sk.png)

Fact-Dimension Join / Star Schema Query:

SELECT

`    `f.fact\_sk,\
`   `f.user\_sk,\
`   `u.id,\
`   `n.name,\
`   `e.email,\
`   `st.status,\
`   `f.event\_ts,\
`   `u.start\_date,\
`   `u.end\_date,\
`   `u.is\_current,\
`   `u.is\_deleted\
FROM demo\_snowflake.fact\_user\_activity f

JOIN demo\_snowflake.dim\_user u      ON f.user\_sk = u.user\_sk\
JOIN demo\_snowflake.dim\_name n      ON u.name\_sk = n.name\_sk\
JOIN demo\_snowflake.dim\_email e     ON u.email\_sk = e.email\_sk\
JOIN demo\_snowflake.dim\_status st   ON u.status\_sk = st.status\_sk\
ORDER BY f.fact\_sk;

Retrieves a full view of user activity by joining the fact table with multiple dimension tables, showing user details, status, and historical info in a star-schema format.

![UserActivity_FactDimension_Join.](Images/UserActivity_FactDimension_Join.png)

-- Time Travel (Statement ID & Timestamp)

So, basically, this section demonstrates how Snowflake Time Travel is used to recover data that was accidentally deleted or modified. I use both statement-ID-based and timestamp-based queries to view data as it existed at a specific point in time. This helps in rolling back changes and auditing data without relying on backups or physical data copies. Overall, it shows Snowflake’s built-in data protection within the configured retention period.

![Time_Travel.](Images/Time_Travel.png)

-- Fail-safe

So, basically, Fail-safe is Snowflake’s last-resort data recovery layer that comes into play after the Time Travel retention period ends. It is mainly used for disaster recovery and can only be accessed through Snowflake Support.

-- Zero-Copy Cloning

So, basically, Zero-Copy Cloning creates an instant snapshot of a table without physically copying data. Any changes made to the source table after cloning do not impact the clone, making it ideal for testing, validation, and recovery scenarios.

![Zero-copy_cloning.](Images/Zero-copy_cloning.png)

-- Query Profile & Performance

So, basically, Query Profile helps analyze how much data is scanned and how efficiently Snowflake executes a query. When result caching is enabled, repeated queries return instantly with zero data scanned, significantly improving performance. When caching is disabled, Snowflake reads data again from storage, increasing both data scanned and execution time. Overall, Query Profile helps understand performance, data pruning, and cost impact.

![Query_profile.](Images/Query_profile.png)

![Query_profile_Monitoring.](Images/Query_profile_Monitoring.png)

-- Views & Materialized Views

So, basically, a view provides a logical layer on top of the GOLD table and always reads the latest data from the base table. It does not store data physically and is mainly used to simplify queries and control access. A materialized view, on the other hand, physically stores query results to improve performance for frequent or heavy queries. Overall, views are used for flexibility and materialized views for performance optimization.

![Materialized_views.](Images/Materialized_views.png)

