#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
export TARGET_ENV=$TARGET_ENV
export PODMAN_WORKDIR=$PODMAN_WORKDIR
set +o history

SECERT_ID=\$(set +x; podman run --rm \
  --env-host \
  $PODMAN_REGISTRY/vault unwrap -field=secret_id $WRAPPED_SECRET_ID)
APP_VAULT_TOKEN=\$(set +x; podman run --rm \
  --env-host \
  vault write -force -field=token auth/vs_apps_approle/login role_id=$ROLE_ID secret_id=\$SECERT_ID)

VAULT_TOKEN=$APP_VAULT_TOKEN podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/liquibase/changelog \
  --env-host \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_CONSUL_TEMPLATE \
  -config "/liquibase/changelog/config.hcl" \
  -template "/liquibase/changelog/liquibase.properties.tpl:${PODMAN_WORKDIR}/liquibase.properties" \
  -once
EOF
