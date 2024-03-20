#!/bin/bash

set -x

# Loop until parameter file is found
while true; do
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

# Create a directory named 'app'
mkdir /app

# Change the current directory to 'app'
cd /app

# Clone a Git repository based on the COMPONENT variable
git clone https://github.com/balusena/${COMPONENT}

# Change directory to the schema directory within the cloned repository
cd ${COMPONENT}/schema

# Check if the schema type is MongoDB
if [ "${SCHEMA_TYPE}" == "mongo" ]; then
  # Download the certificate file
  curl -s -L https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /app/rds-combined-ca-bundle.pem

  # Check if TLS is enabled
  if [ "${TLS_ENABLED}" == "true" ]; then
    # Connect to MongoDB using TLS
    mongo --tls --host ${DOCDB_ENDPOINT}:27017 --tlsCAFile /app/rds-combined-ca-bundle.pem --username ${DOCDB_USERNAME} --password ${DOCDB_PASSWORD} <${COMPONENT}.js
  else
    # Connect to MongoDB using SSL
    mongo --ssl --host ${DOCDB_ENDPOINT}:27017 --sslCAFile /app/rds-combined-ca-bundle.pem --username ${DOCDB_USERNAME} --password ${DOCDB_PASSWORD} <${COMPONENT}.js
  fi

# Check if the schema type is MySQL
elif [ "${SCHEMA_TYPE}" == "mysql" ]; then
  # Check if the 'cities' database exists
  echo show databases | mysql -h ${MYSQL_ENDPOINT} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} | grep cities
  # If 'cities' database does not exist, execute an SQL file
  if [ $? -ne 0 ]; then
    mysql -h ${MYSQL_ENDPOINT} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} <${COMPONENT}.sql
  fi
else
  # Display an error message
  echo Invalid Schema Input
  # Exit the script with an error code
  exit 1
fi
