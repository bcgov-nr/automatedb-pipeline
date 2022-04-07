#!/usr/bin/env bash

cd "${0%/*}"

POLICIES=${POLICIES:=-policy=system/admin-super -policy=system/admin-super}

echo $(vault token create -wrap-ttl=60s -field=wrapping_token $POLICIES)
