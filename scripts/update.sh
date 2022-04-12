#!/usr/bin/env bash

cd "${0%/*}/../db"

# Display status
liquibase status

# Perform application migration for version ${ VERSION }
liquibase update -Dapp_version=${VERSION}

# Tag database for version ${ VERSION }
liquibase tag ${VERSION}
