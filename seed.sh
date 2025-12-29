#!/usr/bin/env bash
set -e

echo "==> Starting MongoDB seed..."

# Encode password
urlencode() {
    local raw="$1"
    local encoded=""
    local i c o
    for ((i=0; i<${#raw}; i++)); do
        c="${raw:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) o="$c" ;;
            *) printf -v o '%%%02X' "'$c"
        esac
        encoded+="$o"
    done
    echo "$encoded"
}

ENCODED_PASSWORD=$(urlencode "$MONGO_PASSWORD")
echo "==> Encoded password: $ENCODED_PASSWORD"

mkdir -p /seed/data
echo "==> Log directory created at /seed/data"

MONGO_URI="mongodb://${MONGO_USERNAME}:${ENCODED_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/?directConnection=true"
echo "==> MongoDB URI: $MONGO_URI"

# Retry connection up to 5 times
MAX_RETRIES=5
for i in $(seq 1 $MAX_RETRIES); do
    echo "==> Checking connection to MongoDB (attempt $i)..."
    if mongosh "$MONGO_URI" --eval "print('connected')" > /seed/data/mongo_check.log 2>&1; then
        echo "==> MongoDB connect success!"
        break
    else
        echo "==> Cannot connect yet, retrying in 5s..."
        sleep 5
    fi
    if [ $i -eq $MAX_RETRIES ]; then
        echo "==> ERROR: Failed to connect to MongoDB after $MAX_RETRIES attempts."
        cat /seed/data/mongo_check.log
        exit 1
    fi
done

# Import users.json
echo "==> Importing users.json..."
if mongoimport "$MONGO_URI" --authenticationDatabase "$MONGO_DATABASE" --db "$MONGO_DATABASE" --collection users --type json --file /seed/users.json --jsonArray > /seed/data/users_import.log 2>&1; then
    echo "==> users.json imported successfully."
else
    echo "==> ERROR importing users.json"
    cat /seed/data/users_import.log
    exit 1
fi

# Import products.json
echo "==> Importing products.json..."
if mongoimport "$MONGO_URI" --authenticationDatabase "$MONGO_DATABASE" --db "$MONGO_DATABASE" --collection products --type json --file /seed/products.json --jsonArray > /seed/data/products_import.log 2>&1; then
    echo "==> products.json imported successfully."
else
    echo "==> ERROR importing products.json"
    cat /seed/data/products_import.log
    exit 1
fi

echo "==> MongoDB seed finished!"
