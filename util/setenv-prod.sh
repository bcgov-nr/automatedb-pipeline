#!/usr/bin/env bash

export VAULT_ADDR="https://vault-iit.apps.silver.devops.gov.bc.ca"
export VAULT_TOKEN=$(vault login -method=oidc -tls-skip-verify -token-only)
