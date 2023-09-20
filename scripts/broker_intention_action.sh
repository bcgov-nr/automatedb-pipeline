#!/usr/bin/env bash

ACTION_TOKEN=$(echo $INTENTION_JSON | /sw_ux/bin/jq -r ".actions.$2.token")

curl -s -X POST $BROKER_URL/v1/intention/action/$1 -H 'X-Broker-Token: '"$ACTION_TOKEN"''
