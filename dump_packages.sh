#!/bin/bash

set -eux

cd "$(dirname $0)"

# Source dump parameters
. ./dump_parameters||{
  echo 'ERROR: Please create `dump_parameters` file from `dump_parameters.template`'
  exit 1
}

if (($# == 0)); then
  echo "Usage: $(basename $0) (SCHEMA) [PACKAGE]"
  exit 1
fi

# Convert to lower case
set +u
db_schema=$(echo "$1"|tr '[:upper:]' '[:lower:]')
db_package=$(echo "$2"|tr '[:upper:]' '[:lower:]')
set -u

# Setup
mkdir out 2>/dev/null||true
chmod 0777 ./out
# Run dump
docker run --rm -i --net="${DOCKER_NETWORK}" --volume="$(realpath .):/mnt/" \
  klo2k/sqlplus -L "${SQLPLUS_CONNECTION_STRING}" @/mnt/dump_packages.sql "${db_schema}" "${db_package}"
# Cleanup
chmod 0750 out

echo "SUCCESS: Dumped to $(realpath .)/out/"
