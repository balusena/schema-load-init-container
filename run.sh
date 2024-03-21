#!/bin/bash

set -x

# Ensure that MongoDB credentials and endpoint are set
if [[ -z "${DOCDB_USERNAME}" || -z "${DOCDB_PASSWORD}" || -z "${DOCDB_ENDPOINT}" ]]; then
    echo "ERROR: MongoDB credentials or endpoint are not set."
    exit 1
fi

# Define a function to check MongoDB connectivity
check_mongo_connection() {
    mongo --ssl --host ${DOCDB_ENDPOINT}:27017 --sslCAFile /app/rds-combined-ca-bundle.pem --username ${DOCDB_USERNAME} --password ${DOCDB_PASSWORD} --eval "db.runCommand('ping')" >/dev/null 2>&1
}

# Wait for MongoDB connectivity
while ! check_mongo_connection; do
    echo "$(date) - Waiting for MongoDB connection"
    sleep 5
done

echo "$(date) - MongoDB connection established"

# Proceed with the rest of the script
while true ; do
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

mkdir /app
cd /app
git clone https://github.com/balusena/${COMPONENT}
cd ${COMPONENT}/schema

if [ "${SCHEMA_TYPE}" == "mongo" ]; then
  curl -s -L https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /app/rds-combined-ca-bundle.pem
  mongo --ssl --host ${DOCDB_ENDPOINT}:27017 --sslCAFile /app/rds-combined-ca-bundle.pem --username ${DOCDB_USERNAME} --password ${DOCDB_PASSWORD} <${COMPONENT}.js
elif [ "${SCHEMA_TYPE}" == "mysql" ]; then
  echo show databases | mysql -h ${MYSQL_ENDPOINT} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} | grep cities
  if [ $? -ne 0 ]; then
    mysql -h ${MYSQL_ENDPOINT} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} <${COMPONENT}.sql
  fi
else
  echo Invalid Schema Input
  exit 1
fi
