#!/usr/bin/env bash

# Rollback to version pre${cd_version}
liquibase rollback pre${cd_version} -Dapp_version=${cd_version}
