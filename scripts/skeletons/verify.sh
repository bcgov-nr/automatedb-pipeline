#!/usr/bin/env bash

cd "${0%/*}/../db"

liquibase generate-changelog --changelog-file=changelog-pre.xml

../update.sh

liquibase rollback ${LAST_VERSION}

# Display status
liquibase status

liquibase generate-changelog --changelog-file=changelog-post.xml

# Fail if changelog changesets do not match
../schema_tools/compare-changelog.sh changelog-pre.xml changelog-post.xml
