#!/usr/bin/env bash

cd "${0%/*}"

export VAULT_ADDR="https://vault-iit.apps.silver.devops.gov.bc.ca"
export VAULT_TOKEN=$(vault login -method=oidc -tls-skip-verify -token-only)
export ENVIRONMENT=dev
POLICIES=${POLICIES:=-policy=system/admin-super -policy=system/admin-super}
VAULT_TOKEN=$(vault token create $POLICIES -wrap-ttl=60s -field=wrapping_token) ../scripts/properties.sh
