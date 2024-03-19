#!/bin/bash

set -euo pipefail

# Wait for the parameters file to be available
while true; do
  if [ -f /data/params ]; then
    echo "### Parameters"
    cat /data/params
    source /data/params
    break
  else
    echo "$(date) - Waiting for Parameters"
    sleep 5
  fi
done

# Create directory for the app and clone the repository
mkdir -p /app
cd /app
git clone "https://github.com/balusena/${COMPONENT}"
cd "${COMPONENT}/schema"

# Execute schema initialization based on the schema type
if [ "${SCHEMA_TYPE}" == "mongo" ]; then
  # Download the truststore file for MongoDB if needed
  curl -s -L https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /app/rds-combined-ca-bundle.pem
  # Execute MongoDB initialization script
  mongo --ssl --host "${DOCDB_ENDPOINT}:27017" --sslCAFile /app/rds-combined-ca-bundle.pem --username "${DOCDB_USERNAME}" --password "${DOCDB_PASSWORD}" < "${COMPONENT}.js"
elif [ "${SCHEMA_TYPE}" == "mysql" ]; then
  # Check if the database exists before executing the MySQL script
  echo "show databases" | mysql -h "${MYSQL_ENDPOINT}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" | grep cities || \
    mysql -h "${MYSQL_ENDPOINT}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" < "${COMPONENT}.sql"
else
  echo "Invalid Schema Input"
  exit 1
fi
