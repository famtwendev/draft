# draft
README
```py
from pymongo import MongoClient
from datetime import datetime
import sys

MONGO_URI = "mongodb://admin:Admin%40123@192.168.20.163:9328/?directConnection=true"

print("=== MongoDB Replica Set Load Test ===")

try:
    # 1. Kết nối MongoDB
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)

    # 2. Test connection (ping)
    client.admin.command("ping")
    print("[OK] Connected to MongoDB")

    # 3. Kiểm tra Primary
    ismaster = client.admin.command("isMaster")
    print(f"[INFO] Primary node: {ismaster.get('primary')}")

except Exception as e:
    print("[ERROR] Cannot connect to MongoDB")
    print(e)
    sys.exit(1)

# 4. Chọn DB và collection
db = client.testdb
col = db.load_test

print("[INFO] Start inserting data...")

# 5. Insert dữ liệu để tạo write load
TOTAL = 100000

for i in range(TOTAL):
    col.insert_one({
        "index": i,
        "message": "replica set write test",
        "createdAt": datetime.now()
    })

    if i % 1000 == 0:
        print(f"[INSERT] Inserted {i}/{TOTAL}")

print("[DONE] Insert finished")

client.close()
print("[INFO] Connection closed")

```
