# Snowflake Streams – Conceptual Guide
Understanding Streams

Snowflake Streams provide Change Data Capture (CDC) by monitoring row-level changes—INSERT, UPDATE, and DELETE—on a source object. Instead of reprocessing full datasets, streams allow downstream systems to consume only the modified data.

Streams are widely used in incremental ETL/ELT pipelines, near real-time analytics, and task-based data workflows.

Internal Working of Streams

When a stream is defined, Snowflake captures a transactional reference point representing the current state of the source object. From that moment onward:

All DML changes are tracked automatically

The stream exposes only the changes since the last processed offset

No physical data is stored inside the stream

Conceptually, a stream acts like a time-based marker over a table’s change history.

Objects That Support Streams

Streams can be created on the following source types:

Regular tables (including shared tables)

Views and secure views

Dynamic tables

External tables and directory tables

Snowflake-managed Apache Iceberg™ tables (with certain restrictions)

Reading and Advancing Streams

An important behavior of streams is offset progression:

Running a SELECT query does not advance the stream

Using the stream in a DML operation (INSERT, CTAS, COPY INTO) consumes the changes

Once consumed, the same change records are no longer accessible

For parallel consumers, separate streams must be created per consumer

Transaction Consistency

Streams follow repeatable read isolation, ensuring predictable processing:

Multiple statements within a transaction see identical change data

Changes generated during a transaction become visible only after commit

Rolled-back transactions do not advance the stream offset

This guarantees reliable and deterministic CDC behavior.

System-Generated Metadata Columns

Querying a stream returns both the source columns and additional metadata:

METADATA$ACTION – Indicates INSERT or DELETE

METADATA$ISUPDATE – TRUE when part of an UPDATE

METADATA$ROW_ID – Permanent identifier for the affected row

Internally, UPDATE operations are represented as a DELETE followed by an INSERT.

Stream Variants

Snowflake supports multiple stream types based on use case:

Standard Streams

Capture INSERT, UPDATE, DELETE, and TRUNCATE

Provide net row-level changes

Best suited for complete CDC pipelines

Append-Only Streams

Capture INSERT operations only

Ignore updates and deletes

Optimized for ingestion-focused workloads

Insert-Only Streams

Designed for external tables and externally managed Iceberg tables

Track newly added files or rows only

Retention Window and Stream Expiry

Streams depend on the data retention period of the source object:

If changes are not consumed within the retention window, the stream becomes stale

Stale streams must be dropped and recreated

Snowflake may temporarily extend retention (up to 14 days) to reduce staleness risk

The STALE_AFTER timestamp indicates when a stream is expected to expire.

Access Control Requirements

To read from a stream, the active role must have:

USAGE on the database and schema

SELECT on the stream

SELECT on the underlying source table or view

Why Streams Are Essential

Streams enable:

Efficient incremental data movement

Strong transactional guarantees

Scalable CDC without data duplication

They serve as the backbone for Snowflake Tasks, real-time pipelines, and event-driven architectures.

Snowflake Tasks – Automation Framework
What Are Tasks?

Snowflake Tasks provide a native automation mechanism for executing SQL statements or stored procedures within Snowflake. They remove the dependency on external schedulers for many pipeline use cases.

Tasks are commonly used for incremental transformations, data loads, and multi-step workflows.

Value of Snowflake Tasks

In production-grade data platforms, automation is critical. Tasks help by:

Scheduling recurring transformations

Supporting event-based executions

Minimizing operational complexity

Delivering consistent, traceable executions

Tasks are frequently paired with Streams to process only newly arrived data.

Execution Model

Once a task is created:

It is initially placed in a SUSPENDED state

It runs SQL or stored procedures when triggered

Each execution is logged and versioned by Snowflake

Tasks begin executing automatically after being resumed.

Task Dependencies and Pipelines

Snowflake supports task graphs for orchestrating workflows:

Tasks can execute sequentially or concurrently

Downstream tasks wait for upstream task completion

Enables multi-stage pipelines such as ingest → transform → publish

This allows Snowflake to act as a lightweight orchestration engine.

Compute Options for Tasks

Tasks require compute resources, which can be provisioned in two ways:

Serverless Tasks

Compute is fully managed by Snowflake

Resources scale dynamically per execution

Ideal for small, predictable workloads

No warehouse setup required

Limitation: maximum size equivalent to an XXLARGE warehouse

User-Managed Tasks

Execute using a specified virtual warehouse

Full control over size and performance

Best for heavy, long-running, or variable workloads

Preferred when consistent compute is required

Scheduling and Event Triggers

Tasks support multiple execution patterns:

Time-Based Scheduling

Run at fixed intervals (seconds, minutes, hours)

Support CRON expressions

Snowflake ensures only one scheduled run executes at a time

Stream-Triggered Execution

Automatically runs when stream data is available

Eliminates polling

Enables low-latency, event-driven pipelines

Hybrid Mode

Executes on a schedule, but only if stream data exists

Optimizes responsiveness while controlling costs

Task Lifecycle Management

A typical task workflow includes:

Creating the task

Manually testing using EXECUTE TASK

Enabling execution with ALTER TASK … RESUME

Monitoring execution history and costs

Modifying behavior using ALTER TASK

Tasks can be updated without needing to drop and recreate them.

Observability and Cost Control

Each task run is recorded in task history

Serverless tasks are billed based on actual compute usage

User-managed tasks incur costs when the warehouse is active

Careful scheduling and compute selection help manage expenses

Known Constraints

Key limitations include:

Tasks do not support automatic schema evolution

Only one scheduled instance can run at a time

Serverless tasks have an upper compute size limit

Final Takeaway

Snowflake Tasks provide a robust, built-in automation layer that supports both scheduled and event-driven pipelines, enabling fully managed data workflows directly within Snowflake.

Queries:

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE DATABASE ECOMMERCE_DEMO;
USE DATABASE ECOMMERCE_DEMO;
CREATE OR REPLACE SCHEMA REALTIME_PIPELINE;
USE SCHEMA REALTIME_PIPELINE;

USE WAREHOUSE COMPUTE_WH;

Table Creation ORDERS_RAW

CREATE OR REPLACE TABLE ORDERS_RAW (
    ORDER_ID        NUMBER,
    CUSTOMER_ID     NUMBER,
    ORDER_TIME      TIMESTAMP,
    ORDER_STATUS    STRING,
    ORDER_AMOUNT    NUMBER
);

![ORDERS_RAW_TABLE_CREATION.](Images/ORDERS_RAW_TABLE_CREATION.png)

INSERT INTO ORDERS_RAW (ORDER_ID, CUSTOMER_ID, ORDER_TIME, ORDER_STATUS, ORDER_AMOUNT) VALUES
    (1001, 1, CURRENT_TIMESTAMP, 'PLACED', 50),
    (1002, 2, CURRENT_TIMESTAMP, 'PLACED', 75),
    (1003, 3, CURRENT_TIMESTAMP, 'PLACED', 100);

![InsertingData_on_orders_raw.](Images/InsertingData_on_orders_raw.png)

SELECT * FROM ORDERS_RAW;

![select_orders_raw.](Images/select_orders_raw.png)

CREATE OR REPLACE STREAM ORDERS_STREAM
ON TABLE ORDERS_RAW;

![select_orders_raw.](Images/select_orders_raw.png)

INSERT INTO ORDERS_RAW (ORDER_ID, CUSTOMER_ID, ORDER_TIME, ORDER_STATUS, ORDER_AMOUNT) VALUES
    (1004, 4, CURRENT_TIMESTAMP, 'PLACED', 120),
    (1005, 5, CURRENT_TIMESTAMP, 'PLACED', 200);


![Orders_raw_insertion.](Images/Orders_raw_insertion.png)

SELECT * FROM ORDERS_STREAM;

![select_orders_streams.](Images/select_orders_streams.png)

CREATE OR REPLACE TABLE ORDERS_ANALYTICS AS
SELECT
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_TIME,
    ORDER_STATUS,
    ORDER_AMOUNT
FROM ORDERS_RAW
WHERE 1 = 2;  

![ORDERS_ANALYTICS_TABLE_CREATION.](Images/ORDERS_ANALYTICS_TABLE_CREATION.png)

SELECT * FROM ORDERS_ANALYTICS;

![Select_orders_analytics.](Images/Select_orders_analytics.png)


CREATE OR REPLACE TASK LOAD_ORDERS_TO_ANALYTICS
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('ORDERS_STREAM')
AS
INSERT INTO ORDERS_ANALYTICS (
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_TIME,
    ORDER_STATUS,
    ORDER_AMOUNT
)
SELECT
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_TIME,
    ORDER_STATUS,
    ORDER_AMOUNT
FROM ORDERS_STREAM;

![Load_Orders_to_analytics.](Images/Load_Orders_to_analytics.png)


ALTER TASK LOAD_ORDERS_TO_ANALYTICS RESUME;

![Alter_Resume_on_orders_Analytics.](Images/Alter_Resume_on_orders_Analytics.png)

INSERT INTO ORDERS_RAW (ORDER_ID, CUSTOMER_ID, ORDER_TIME, ORDER_STATUS, ORDER_AMOUNT) VALUES
    (1006, 6, CURRENT_TIMESTAMP, 'PLACED', 220),
    (1007, 7, CURRENT_TIMESTAMP, 'PLACED', 260);

![6_and_7.](Images/6_and_7.png)


SELECT * FROM ORDERS_ANALYTICS;

![Select_orders_analytics.](Images/Select_orders_analytics.png)


SHOW TASKS LIKE 'LOAD_ORDERS_TO_ANALYTICS';

![Show_tasks_using_like.](Images/Show_tasks_using_like.png)

SELECT
  NAME,
  STATE,
  SCHEDULED_TIME,
  QUERY_START_TIME,
  COMPLETED_TIME,
  ERROR_MESSAGE
FROM TABLE(
  INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'LOAD_ORDERS_TO_ANALYTICS',
    RESULT_LIMIT => 10
  )
);

![TaskHistory_Information.](Images/TaskHistory_Information.png)

SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE NAME = 'LOAD_ORDERS_TO_ANALYTICS'
ORDER BY COMPLETED_TIME DESC;


![Select_task_history.](Images/Select_task_history.png)

SHOW STREAMS;

![Streams_Img1.](Images/Streams_Img1.png)

![Streams_Img2.](Images/Streams_Img2.png)