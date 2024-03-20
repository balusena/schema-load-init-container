#!/bin/bash

# Purpose: This script automates the deployment and configuration process for database schemas.
# It retrieves parameters, clones a Git repository, and executes database scripts based on the schema type.

# Start debugging output
set -x

# Loop until parameter file is found
while true; do
    # Check if parameter file exists
    if [ -f /data/params ]; then
        # Display parameters
        echo "### Parameters"
        cat /data/params
        # Load parameters from file
        source /data/params
        break
    else
        # Display current date while waiting
        echo $(date) - Waiting for Parameters
        # Wait for 5 seconds before checking again
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
    # Download a certificate file
    curl -s -L https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /app/rds-combined-ca-bundle.pem
    # Connect to MongoDB and execute a JavaScript file
    mongo --ssl --host ${DOCDB_ENDPOINT}:27017 --sslCAFile /app/rds-combined-ca-bundle.pem --username ${DOCDB_USERNAME} --password ${DOCDB_PASSWORD} <${COMPONENT}.js
    # Connect to MongoDB and execute a JavaScript file
    #mongo --tls --host ${DOCDB_ENDPOINT}:27017 --tlsCAFile /app/rds-combined-ca-bundle.pem --username ${DOCDB_USERNAME} --password ${DOCDB_PASSWORD} <${COMPONENT}.js

# Check if the schema type is MySQL
elif [ "${SCHEMA_TYPE}" == "mysql" ]; then
    # Check if the 'cities' database exists
    echo show databases | mysql -h ${MYSQL_ENDPOINT} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} | grep cities
    # If 'cities' database does not exist, execute an SQL file
    if [ $? -ne 0 ]; then
        mysql -h ${MYSQL_ENDPOINT} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} <${COMPONENT}.sql
    fi
else  # If the schema type is neither MongoDB nor MySQL
    # Display an error message
    echo Invalid Schema Input
    # Exit the script with an error code
    exit 1
fi
