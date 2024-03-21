#!/bin/bash

set -euo pipefail

# Function to log messages with timestamp
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check MongoDB connection status
check_mongodb_status() {
    echo "Checking MongoDB connection status..."
    if mongo --quiet --eval "db.runCommand('ping')" "$MONGO_URL"; then
        echo "MongoDB is up and running."
    else
        echo "Failed to connect to MongoDB."
    fi
}

# Function to attempt connecting to MongoDB with retry
connect_to_mongodb_with_retry() {
    echo "Attempting to connect to MongoDB with retry..."
    for ((i=1; i<=$RETRY_COUNT; i++)); do
        echo "Attempt $i to connect to MongoDB..."
        if mongo --quiet --eval "db.runCommand('ping')" "$MONGO_URL"; then
            echo "Connection successful!"
            exit 0
        else
            echo "Connection failed. Retrying in $WAIT_TIME seconds..."
            sleep $WAIT_TIME
        fi
    done
    echo "Failed to connect to MongoDB after $RETRY_COUNT attempts."
    exit 1
}

# Validate if the parameter file exists
if [ ! -f /data/params ]; then
  log_message "ERROR: Parameter file '/data/params' not found."
  exit 1
fi

# Source parameters from the file
source /data/params

# Validate required parameters
if [ -z "${COMPONENT}" ] || [ -z "${SCHEMA_TYPE}" ] || [ -z "${MONGO_URL}" ] || [ -z "${DOCDB_USERNAME}" ] || [ -z "${DOCDB_PASSWORD}" ]; then
  log_message "ERROR: Missing required parameters."
  exit 1
fi

# Print MongoDB URL for debugging
log_message "MongoDB URL: ${MONGO_URL}"

# Clone the Git repository
mkdir -p /app && cd /app
if ! git clone "https://github.com/balusena/${COMPONENT}" &>/dev/null; then
  log_message "ERROR: Failed to clone Git repository."
  exit 1
fi

# Navigate to the schema directory
cd "${COMPONENT}/schema" || { log_message "ERROR: Directory 'schema' not found."; exit 1; }

# Establish MongoDB connection and execute schema initialization script if SCHEMA_TYPE is mongo
if [ "${SCHEMA_TYPE}" == "mongo" ]; then
  # Download certificate bundle
  if ! curl -s -L "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -o /app/rds-combined-ca-bundle.pem; then
    log_message "ERROR: Failed to download certificate bundle."
    exit 1
  fi

  # Connect to MongoDB and execute schema initialization script
  if ! mongo --ssl --host "${MONGO_URL}" --sslCAFile /app/rds-combined-ca-bundle.pem --username "${DOCDB_USERNAME}" --password "${DOCDB_PASSWORD}" <"${COMPONENT}.js"; then
    log_message "ERROR: Failed to connect to MongoDB or execute schema initialization script."
    exit 1
  fi

# Handle other schema types (e.g., mysql)
elif [ "${SCHEMA_TYPE}" == "mysql" ]; then
  # Your MySQL initialization logic here
  log_message "MySQL initialization logic"

else
  log_message "ERROR: Invalid SCHEMA_TYPE '${SCHEMA_TYPE}'."
  exit 1
fi

log_message "Schema initialization completed successfully."

# Define variables
MONGO_URL="mongodb://roboshop:roboshop123@docdb-prod.cluster-cfo8mcqcknol.us-east-1.docdb.amazonaws.com:27017/catalogue?tls=true&replicaSet=rs0"
RETRY_COUNT=3
WAIT_TIME=5

# Call the functions to check MongoDB status and attempt connection with retry
check_mongodb_status
connect_to_mongodb_with_retry

exit 0
