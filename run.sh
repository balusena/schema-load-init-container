#!/bin/bash

set -x

while true ; do
  if [ -f /data/params ]; then
    echo "### Parameters"
    cat /data/params
    source /data/params
    break
  else
    echo $(date) - Waiting for Parameters
    sleep 5
  fi
done

mkdir /app
cd /app
git clone https://github.com/balusena/${COMPONENT}
cd ${COMPONENT}/schema

source /data/params

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