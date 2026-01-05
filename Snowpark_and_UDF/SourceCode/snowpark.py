from snowflake_config import create_session
from snowflake.snowpark.functions import col, when, current_timestamp


def main():
    # 1️⃣ Create Snowflake session
    try:
        session = create_session()
        print("✅ Snowflake connection successful!")
    except Exception as e:
        print("❌ Snowflake connection failed:", e)
        return

    # 2️⃣ Sample in-memory data
    data = [
        (1001, 1, 50.0),
        (1002, 2, 120.0),
        (1003, 3, 75.0),
        (1004, 4, 250.0),
    ]

    # 3️⃣ Create Snowpark DataFrame
    df = session.create_dataframe(
        data,
        schema=["ORDER_ID", "CUSTOMER_ID", "ORDER_AMOUNT"]
    )

    # 4️⃣ Apply transformations
    df_enriched = (
        df.with_column("INGESTED_AT", current_timestamp())
          .with_column(
              "ORDER_TIER",
              when(col("ORDER_AMOUNT") >= 200, "PLATINUM")
              .when(col("ORDER_AMOUNT") >= 100, "GOLD")
              .otherwise("SILVER")
          )
    )

    # 5️⃣ Save DataFrame as Snowflake table
    df_enriched.write.mode("overwrite").save_as_table(
        "ORDERS_ENRICHED_SNOWPARK"
    )

    # 6️⃣ Show results
    df_enriched.show()

    print("✅ Data successfully written to DEMO_PROJECT.DEMO_SNOWFLAKE.ORDERS_ENRICHED_SNOWPARK")


if __name__ == "__main__":
    main()
