#!/bin/sh

TOKEN=$(echo $INTENTION_JSON | /sw_ux/bin/jq -r '.actions.login.token')

WRAPPED_VAULT_TOKEN=$(curl -s -X POST $BROKER_URL/v1/provision/token/self \
  -H 'Content-Type: application/json' \
  -H 'X-Vault-Role-Id: '"$CONFIG_ROLE_ID"'' -H 'X-Broker-Token: '"$TOKEN"'' | \
  /sw_ux/bin/jq -r '.wrap_info.token')

VAULT_ADDR=$VAULT_ADDR /sw_ux/bin/vault unwrap -field=token $WRAPPED_VAULT_TOKEN
