# draft
README
```py
from pymongo import MongoClient
from datetime import datetime
from threading import Thread
import sys

# ==== Cấu hình ====
MONGO_URI = "mongodb://admin:Admin%40123@192.168.20.163:9328/?directConnection=true"
DB_NAME = "testdb"
COLLECTION_NAME = "load_test"
TOTAL = 1000000          # Tổng số document
BATCH_SIZE = 1000        # Số document insert mỗi batch
THREADS = 5              # Số luồng concurrent insert

print("=== MongoDB Replica Set Stress Test ===")

# ==== Kết nối MongoDB ====
try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    print("[OK] Connected to MongoDB")

    ismaster = client.admin.command("isMaster")
    print(f"[INFO] Primary node: {ismaster.get('primary')}")

except Exception as e:
    print("[ERROR] Cannot connect to MongoDB")
    print(e)
    sys.exit(1)

db = client[DB_NAME]
col = db[COLLECTION_NAME]

# ==== Hàm insert theo batch cho 1 thread ====
def insert_worker(start, end):
    batch = []
    for i in range(start, end):
        batch.append({
            "index": i,
            "message": "replica set write stress test",
            "createdAt": datetime.now()
        })

        if len(batch) >= BATCH_SIZE:
            col.insert_many(batch)
            batch = []
            print(f"[Thread-{start}] Inserted {i-start+1} docs")

    if batch:
        col.insert_many(batch)
        print(f"[Thread-{start}] Inserted remaining {len(batch)} docs")

# ==== Tính khoảng cho mỗi thread ====
step = TOTAL // THREADS
threads = []

for t in range(THREADS):
    start = t * step
    # thread cuối chạy đến TOTAL
    end = TOTAL if t == THREADS - 1 else (t + 1) * step
    th = Thread(target=insert_worker, args=(start, end))
    threads.append(th)
    th.start()

# ==== Chờ tất cả thread kết thúc ====
for th in threads:
    th.join()

client.close()
print("[DONE] Stress test finished. Connection closed.")


```
