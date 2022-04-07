#!/usr/bin/env bash

cd "${0%/*}"

export ENVIRONMENT=dev
VAULT_TOKEN=$(./wrapped-app-token.sh) ../scripts/properties.sh
