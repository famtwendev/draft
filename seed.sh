#!/usr/bin/env bash
set -e

echo "==> Starting MongoDB seed..."

# Encode password cho URI (handle ký tự đặc biệt)
urlencode() {
    local raw="$1"
    local length="${#raw}"
    local i
    local c
    for (( i = 0; i < length; i++ )); do
        c="${raw:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) printf "%s" "$c" ;;
            *) printf "%%%02X" "'$c" ;;
        esac
    done
}

ENCODED_PASSWORD=$(urlencode "$MONGO_PASSWORD")

# Thư mục lưu log
mkdir -p /seed/data

# MongoDB URI
MONGO_URI="mongodb://${MONGO_USERNAME}:${ENCODED_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/${MONGO_DATABASE}?authSource=${MONGO_DATABASE}&directConnection=true"

# Kiểm tra kết nối
echo "==> Checking connection to MongoDB at $MONGO_HOST:$MONGO_PORT ..."
if ! mongosh "$MONGO_URI" --eval "print('connected')" > /seed/data/mongo_check.log 2>&1; then
    echo "==> ERROR: Cannot connect to MongoDB."
    echo "==> See /seed/data/mongo_check.log"
    exit 1
fi
echo "==> MongoDB is reachable."

# Import users.json
echo "==> Importing users.json..."
if ! mongoimport "$MONGO_URI" --collection users --type json --file /seed/users.json --jsonArray > /seed/data/users_import.log 2>&1; then
    echo "==> ERROR: Failed to import users.json."
    echo "==> See /seed/data/users_import.log"
    exit 1
fi
echo "==> users.json imported successfully."

# Import products.json
echo "==> Importing products.json..."
if ! mongoimport "$MONGO_URI" --collection products --type json --file /seed/products.json --jsonArray > /seed/data/products_import.log 2>&1; then
    echo "==> ERROR: Failed to import products.json."
    echo "==> See /seed/data/products_import.log"
    exit 1
fi
echo "==> products.json imported successfully."

echo "==> MongoDB seed finished!"
