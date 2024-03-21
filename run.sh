#!/bin/bash

set -euo pipefail

# Function to log messages with timestamp
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
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
exit 0
