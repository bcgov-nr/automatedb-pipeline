#!/usr/bin/env bash

cd "${0%/*}/../db"

# Display status
liquibase status

# Perform application migration for version ${ cd_version }
liquibase update -Dapp_version=${VERSION}

# Tag database for version ${ cd_version }
liquibase tag ${VERSION}
