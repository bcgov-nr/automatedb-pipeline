#!/usr/bin/env bash

cd "${0%/*}"

# Perform application migration for version ${ cd_version }
liquibase update -Dapp_version=${cd_version}

# Tag database for version ${ cd_version }
liquibase tag ${cd_version}
