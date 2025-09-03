set -e

echo "Importing reading_sessions into MongoDB..."
mongoimport \
  --host localhost \
  --port 27017 \
  --username "$MONGO_INITDB_ROOT_USERNAME" \
  --password "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --db "$MONGO_INITDB_DATABASE" \
  --collection reading_sessions \
  --file /docker-entrypoint-initdb.d/reading_sessions.json \
  --jsonArray \
  --drop
echo "Import complete."
