#!/usr/bin/env bash

./schema_tools/${dbtype}-dump.sh pre.db

./update.sh

./rollback.sh
# Rollback to version pre${cd_version}
liquibase rollback pre${cd_version} -Dapp_version=${cd_version}

./schema_tools/${dbtype}-dump.sh post.db

./schema_tools/${dbtype}-compare.sh pre.db post.db