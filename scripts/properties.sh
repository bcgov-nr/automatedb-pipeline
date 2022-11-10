#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
export TARGET_ENV_SHORT=$TARGET_ENV_SHORT
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

PROPERTIES_RC=\$?

# Two exits are required because we are running as another user
# Only send email for prod
if [ \$PROPERTIES_RC -ne 0 ]; then
  if [ "$TARGET_ENV" = "production" ]; then
    echo "${BUILD_URL}" | mailx -s "Error during Liquibase properties generation" NRIDS.ApplicationDelivery@gov.bc.ca
  fi
  exit \$PROPERTIES_RC
  exit \$PROPERTIES_RC
fi
EOF
