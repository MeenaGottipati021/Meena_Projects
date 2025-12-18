# Step 1: Read CSV in Spark
df = spark.read.csv("data.csv", header=True, inferSchema=True)

# Step 2: Add month column
from pyspark.sql.functions import date_format
df = df.withColumn("month", date_format("date", "yyyy-MM"))

# Step 3: Convert to Pandas (to avoid Hadoop error on Windows)
df_pandas = df.toPandas()

# Step 4: Write manually into month partitions using Pandas
import os
for month, subdf in df_pandas.groupby("month"):
    path = f"partitioned_data_month/month={month}"
    os.makedirs(path, exist_ok=True)
    subdf.to_csv(f"{path}/part-0000.csv", index=False)

print("Data successfully partitioned by month and saved!")
