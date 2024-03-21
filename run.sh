#!/bin/bash

set -e

# Function to wait for the parameters file with timeout
wait_for_params() {
  local timeout=300  # Timeout in seconds (adjust as needed)
  local start_time=$(date +%s)
  echo "Waiting for parameters file..."
  while [ ! -f "/data/params" ]; do
    if [ $(($(date +%s) - start_time)) -ge $timeout ]; then
      echo "Timeout waiting for parameters file."
      exit 1
    fi
    sleep 5
  done
  echo "Parameters file found."
}

# Function to print parameters
print_params() {
  echo "### Parameters:"
  cat "/data/params"
}

# Main function to load schema
load_schema() {
  echo "Loading schema..."
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
source "/data/params"  # Source parameters file
print_params
echo "SCHEMA_TYPE after sourcing: ${SCHEMA_TYPE}"  # Debug statement
load_schema
