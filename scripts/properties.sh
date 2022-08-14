#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
export TARGET_ENV=$TARGET_ENV
export PODMAN_WORKDIR=$PODMAN_WORKDIR
set +o history
VAULT_TOKEN=$APP_VAULT_TOKEN podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/liquibase/changelog \
  --env-host \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_CONSUL_TEMPLATE \
  -config "/liquibase/changelog/config.hcl" \
  -template "/liquibase/changelog/liquibase.properties.tpl:${PODMAN_WORKDIR}/liquibase.properties" \
  -once
EOF
