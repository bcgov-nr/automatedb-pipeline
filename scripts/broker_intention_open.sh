#!/usr/bin/env bash

# Workaround because <() does not work
TEMP_FILE="$(mktemp tmp.isss-jenkins-broker.XXXXXXXXXX)"
cat $1 | /sw_ux/bin/jq "\
    .event.provider=\"$EVENT_PROVIDER\" | \
    .event.url=\"$BUILD_URL\" | \
    .user.name=\"$CAUSE_USER_ID\" | \
    (.actions[] | select(.id == \"database\") .service.name) |= \"$DB_COMPONENT\" | \
    (.actions[] | select(.id == \"database\") .service.project) |= \"$PROJECT_KEY\" | \
    (.actions[] | select(.id == \"database\") .service.environment) |= \"$TARGET_ENV\" \
    " > $TEMP_FILE

curl -s -X POST $BROKER_URL/v1/intention/open \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $NR_BROKER_TOKEN" \
    -d @$TEMP_FILE

rm $TEMP_FILE
