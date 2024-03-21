#!/bin/bash

set -euo pipefail

# Function to wait for the parameters file
wait_for_params() {
  while [ ! -f "/data/params" ]; do
    echo "$(date) - Waiting for parameters file..."
    sleep 5
  done
  echo "$(date) - Parameters file found."
}

# Function to print parameters
print_params() {
  echo "### Parameters:"
  cat "/data/params"
}

# Main function to load schema
load_schema() {
  echo "$(date) - Loading schema..."
  echo "SCHEMA_TYPE: ${SCHEMA_TYPE}"  # Debug statement

  # Place your schema loading logic here
  if [ "${SCHEMA_TYPE}" == "mongo" ]; then
    curl -s -L "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -o "/app/rds-combined-ca-bundle.pem"
    mongo --ssl --host "${DOCDB_ENDPOINT}:27017" --sslCAFile "/app/rds-combined-ca-bundle.pem" --username "${DOCDB_USERNAME}" --password "${DOCDB_PASSWORD}" <"${COMPONENT}.js"
  elif [ "${SCHEMA_TYPE}" == "mysql" ]; then
    echo "show databases" | mysql -h "${MYSQL_ENDPOINT}" -u"${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" | grep cities
    if [ $? -ne 0 ]; then
      mysql -h "${MYSQL_ENDPOINT}" -u"${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" <"${COMPONENT}.sql"
    fi
  else
    echo "Invalid Schema Input"
    exit 1
  fi
}

# Execute functions
wait_for_params
print_params
source "/data/params"  # Source parameters file
echo "$(date) - SCHEMA_TYPE after sourcing: ${SCHEMA_TYPE}"  # Debug statement
load_schema

