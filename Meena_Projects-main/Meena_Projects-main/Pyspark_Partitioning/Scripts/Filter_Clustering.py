import pandas as pd
import os
import time

# Read and combine all partitioned files
data_frames = []
for root, dirs, files in os.walk("partitioned_data_month"):
    for file in files:
        if file.endswith(".csv"):
            path = os.path.join(root, file)
            df = pd.read_csv(path)
            data_frames.append(df)

df_combined = pd.concat(data_frames, ignore_index=True)

# STEP 1️⃣: BEFORE FILTER
start_before = time.time()
print("\n=== BEFORE FILTERING ===")
print("Total records:", len(df_combined))
print(df_combined.head(5))
end_before = time.time()
print("Time taken (before):", round(end_before - start_before, 3), "seconds")

# STEP 2️⃣: FILTER (month = 2024-02)
start_after = time.time()
filtered_df = df_combined[df_combined["month"] == "2024-01"]
print("\n=== AFTER FILTERING (month = 2024-01) ===")
print("Total filtered records:", len(filtered_df))
print(filtered_df.head(5))
end_after = time.time()
print("Time taken (after filter):", round(end_after - start_after, 3), "seconds")

# STEP 3️⃣: CLUSTER (sort by region)
clustered_df = filtered_df.sort_values(by="region")
print("\n=== CLUSTERED DATA (by region) ===")
print(clustered_df.head(5))

print("\n Step 4 complete — before & after comparison with timings done!")
