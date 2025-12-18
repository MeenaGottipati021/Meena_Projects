import pandas as pd
import random
from datetime import datetime, timedelta

records = []
regions = ["North", "South", "East", "West"]

for i in range(1, 1001):
    record = {
        "id": i,
        "name": f"User_{i}",
        "region": random.choice(regions),
        "amount": round(random.uniform(100, 1000), 2),
        "date": (datetime(2024, 1, 1) + timedelta(days=random.randint(0, 60))).strftime("%Y-%m-%d")
    }
    records.append(record)

df = pd.DataFrame(records)
df.to_csv("data.csv", index=False)
print("1000 records file 'data.csv' created successfully.")
