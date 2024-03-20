#!/bin/bash

set -euo pipefail

# Function to handle errors gracefully
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Check for the existence of the parameters file and source it
if [ ! -f /data/params ]; then
    handle_error "Parameters file '/data/params' not found."
fi

echo "### Parameters"
cat /data/params
source /data/params

# Validate required parameters
if [[ -z "${COMPONENT}" || -z "${SCHEMA_TYPE}" ]]; then
    handle_error "COMPONENT and SCHEMA_TYPE must be defined in the parameters file."
fi

# Create directory for the application
mkdir -p /app/
cd /app/

# Clone the repository
git clone "https://github.com/balusena/${COMPONENT}" || handle_error "Failed to clone the repository."

# Move to the schema directory
cd "${COMPONENT}/schema" || handle_error "Schema directory not found."

# Handle schema setup based on SCHEMA_TYPE
case "${SCHEMA_TYPE}" in
    "mongo")
        # Download certificate bundle for MongoDB SSL connection
        curl -s -L "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -o "/app/rds-combined-ca-bundle.pem" || handle_error "Failed to download certificate bundle."

        # Setup MongoDB schema
        if ! mongo "${MONGO_URL}" --sslCAFile "/app/rds-combined-ca-bundle.pem" < "${COMPONENT}.js"; then
            handle_error "Failed to setup MongoDB schema."
        fi
        ;;
    "mysql")
        # Check if the database already contains the schema
        if ! echo "SHOW DATABASES;" | mysql -h "${MYSQL_ENDPOINT}" -u"${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" | grep -q "cities"; then
            # Setup MySQL schema if not found
            mysql -h "${MYSQL_ENDPOINT}" -u"${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" < "${COMPONENT}.sql" || handle_error "Failed to setup MySQL schema."
        else
            echo "Schema 'cities' already exists in the database."
        fi
        ;;
    *)
        handle_error "Invalid SCHEMA_TYPE: ${SCHEMA_TYPE}."
        ;;
esac

echo "Schema setup completed successfully."
