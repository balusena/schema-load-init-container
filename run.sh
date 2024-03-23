#!/bin/bash

set -x

mkdir /app
cd /app
git clone https://github.com/balusena/$COMPONENT
cd ${COMPONENT}/schema

source /data/params

if [ "$SCHEMA_TYPE" == "mongo" ]; then
  curl -L -O https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
  mongo --ssl --host $DOCDB_ENDPOINT:27017 --sslCAFile global-bundle.pem --username $DOCDB_USERNAME --password $DOCDB_PASSWORD < $COMPONENT.js
elif [ "$SCHEMA_TYPE" == "mysql" ]; then
  mysql -h ${MYSQL_ENDPOINT} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} < $COMPONENT.sql
else
  echo "Invalid Schema Input"
  exit 1
fi