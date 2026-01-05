Snowpark, DataFrames, and UDFs

-- What is Snowpark?
Snowpark is a developer framework offered by Snowflake that allows you to process data directly within Snowflake using code, primarily Python. Instead of moving data to external systems for processing, Snowpark pushes your logic to Snowflake’s compute engine, improving efficiency.

Snowpark relies on DataFrames, which are similar to database tables or the results of SQL queries. A key feature is lazy execution, meaning operations are not actually performed until an action triggers execution.

-- Snowpark DataFrames (Python)

A DataFrame represents data from a Snowflake table or query. You can transform the data using Python-like commands such as selecting specific columns or filtering rows.

-- Example – Selecting Columns:

from snowflake.snowpark.functions import col

df = session.table("sample_product_data").select(
    col("id"),
    col("name"),
    col("serial_number")
)

df.show()


-- Lazy Execution Example:

df = session.table("sample_product_data").select(col("id"), col("name"))
results = df.collect()


Here, the query runs only when collect() is called.

Writing a DataFrame Back to a Table:
After transforming the data, you can save the result to a Snowflake table.

df.write.mode("overwrite").save_as_table("table1")


mode("overwrite") replaces existing data.

save_as_table() writes the DataFrame to Snowflake.

No separate execution command is needed.

-- User-Defined Functions (UDFs) #

UDFs are custom functions used when built-in Snowflake functions don’t meet your needs. They always return a value and are typically used in SQL queries.

-- Types of UDFs:

Scalar UDF: Returns a single value per row

UDAF: Aggregates multiple rows

UDTF: Returns a table

Vectorized UDF: Processes data in batches

-- Example – Creating a Python UDF:

from snowflake.snowpark.functions import udf
from snowflake.snowpark.types import IntegerType

add_one = udf(
    lambda x: x + 1,
    return_type=IntegerType(),
    input_types=[IntegerType()],
    name="my_udf",
    replace=True
)


-- Using a UDF in SQL:

SELECT MyFunction_1(column_1)
FROM table1;

-- Stored Procedures 

Stored procedures are designed for multi-step logic, such as workflows, automation, or data pipelines. Unlike UDFs, they are executed independently and cannot be used directly in a SELECT statement.

Calling a Stored Procedure:

CALL MyStoredProcedure_1(argument_1);


-- Example – SQL Stored Procedure:

CREATE OR REPLACE PROCEDURE do_stuff(input NUMBER)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
  ERROR VARCHAR DEFAULT 'Bad input. Number must be less than 10.';
BEGIN
  IF (input > 10) THEN
    RETURN ERROR;
  END IF;
END;
$$;

-- UDFs vs Stored Procedures
Feature	UDF	Stored Procedure
Purpose	Return a value	Execute workflow logic
Usage	Inside SELECT	Called with CALL
Return	Always returns a value	Returns status/result
Complexity	Simple	Handles multi-step logic
When to Use	Reusable calculations	Automation and workflows
Key Recommendations

Use Snowpark DataFrames for Python-based data transformations.

Use UDFs for reusable calculations in SQL.

Use Stored Procedures for automation, workflows, and multi-step logic.

-- Summary:
Snowpark allows processing of data in Python directly within Snowflake. UDFs are ideal for calculations that can be reused in SQL queries, whereas stored procedures are better suited for automating tasks and managing workflows.

# snowpark.py 

from snowflake_config import create_session
from snowflake.snowpark.functions import col, when, current_timestamp

1.create_session → Your Snowflake login function
2.col → Used to refer to a column
3.when → Used for IF–ELSE logic
4.current_timestamp → Gets the current time

def main():  //Main Function (This is the entry point of your program.)

Create Snowflake session:
    try:
        session = create_session()
        print("✅ Snowflake connection successful!")
    except Exception as e:
        print("❌ Snowflake connection failed:", e)
        return

  Calls create_session() from snowflake_config.py

Tries to connect to Snowflake
If connection fails → program stops
If successful → continues
session = your active Snowflake connection

  ![connection.](Images/connection.png)   

  Sample in-memory data:
    data = [
        (1001, 1, 50.0),
        (1002, 2, 120.0),
        (1003, 3, 75.0),
        (1004, 4, 250.0),
    ]

This is just fake data:

ORDER_ID
CUSTOMER_ID
ORDER_AMOUNT


![sample_data.](Images/sample_data.png)

  Create Snowpark DataFrame:
    df = session.create_dataframe(
        data,
        schema=["ORDER_ID", "CUSTOMER_ID", "ORDER_AMOUNT"]
    )

Converts Python data → Snowflake DataFrame
Similar to Spark DataFrame
Now Snowflake understands this data

![snowpark_DF_Creation.](Images/snowpark_DF_Creation.png)

  Apply transformations:
    df_enriched = (
        df.with_column("INGESTED_AT", current_timestamp())
          .with_column(
              "ORDER_TIER",
              when(col("ORDER_AMOUNT") >= 200, "PLATINUM")
              .when(col("ORDER_AMOUNT") >= 100, "GOLD")
              .otherwise("SILVER")
          )
    )

ORDER_AMOUNT	ORDER_TIER
≥ 200	          PLATINUM
≥ 100	           GOLD
< 100	           SILVER

This is IF–ELSE logic in Snowpark.

![Applied-Transformations.](Images/Applied-Transformations.png)


  Save DataFrame as Snowflake table:
    df_enriched.write.mode("overwrite").save_as_table(
        "ORDERS_ENRICHED_SNOWPARK"
    )

Creates a table in Snowflake
Table name: ORDERS_ENRICHED_SNOWPARK
overwrite → replaces table if it already exists

![DF_Snowflake_table.](Images/DF_Snowflake_table.png)


  Show results:
    df_enriched.show()

    print("✅ Data successfully written to DEMO_PROJECT.DEMO_SNOWFLAKE.ORDERS_ENRICHED_SNOWPARK")


if __name__ == "__main__":
    main()

“Run main() when this file is executed”

![Visual_Output.](Images/Visual_Output.png) 

![Result.](Images/Result.png)

# check_env.py 

import os
from dotenv import load_dotenv

load_dotenv()

keys = [
    "SNOWFLAKE_ACCOUNT",
    "SNOWFLAKE_USER",
    "SNOWFLAKE_PASSWORD",
    "SNOWFLAKE_ROLE",
    "SNOWFLAKE_WAREHOUSE",
    "SNOWFLAKE_DATABASE",
    "SNOWFLAKE_SCHEMA"
]

for key in keys:
    print(f"{key}: {os.getenv(key)}")


![check_env.](Images/check_env.png)

Queries:

USE DATABASE DEMO_PROJECT;
USE SCHEMA DEMO_SNOWFLAKE;

SELECT * FROM ORDERS_ENRICHED_SNOWPARK; 

![Snowpark_output.](Images/Snowpark_output.png)