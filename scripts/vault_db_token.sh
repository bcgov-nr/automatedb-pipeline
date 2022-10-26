#!/bin/sh

TOKEN=$(echo $INTENTION_JSON | /sw_ux/bin/jq -r '.actions.database.token')

echo -n $(curl -s -X POST $BROKER_URL/v1/provision/token/self \
  -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$DB_ROLE_ID"'' -H 'X-Broker-Token: '"$TOKEN"'' | \
  /sw_ux/bin/jq -r '.wrap_info.token')
