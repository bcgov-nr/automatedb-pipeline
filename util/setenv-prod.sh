#!/usr/bin/env bash
export VAULT_ADDR=https://vault-iit.apps.silver.devops.gov.bc.ca
export VAULT_TOKEN=$(vault login -method=oidc -format json | jq -r '.auth.client_token')
export WRAPPING_TOKEN=$(vault token create -policy=shared/groups/appdelivery/jenkins-isss-cdua-read \
    -policy=shared/apps/dev/liquibase/template-db/database \
    -orphan \
    -explicit-max-ttl=300 \
    -wrap-ttl=300 \
    -field=wrapping_token)