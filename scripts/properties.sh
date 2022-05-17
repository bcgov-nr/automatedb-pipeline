#!/usr/bin/env bash

cd "${0%/*}"

# VAULT_TOKEN environment variable must contain a wrapped vault token.
/sw_ux/bin/consul-template -config "config.hcl" \
  -template "../${TMP_DIR}/liquibase.properties.tpl:../${TMP_DIR}/db/liquibase.properties" \
  -once
