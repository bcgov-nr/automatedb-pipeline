#!/usr/bin/env bash

cd "${0%/*}"

# VAULT_TOKEN environment variable must contain a wrapped vault token.
consul-template -config "config.hcl" -once
