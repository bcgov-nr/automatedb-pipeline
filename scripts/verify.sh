#!/usr/bin/env bash

# TODO: Improve

cd "${0%/*}/../db"

./schema_tools/${dbtype}-dump.sh pre.db

./update.sh

liquibase rollback pre${cd_version} -Dapp_version=${cd_version}

./schema_tools/${dbtype}-dump.sh post.db

./schema_tools/${dbtype}-compare.sh pre.db post.db