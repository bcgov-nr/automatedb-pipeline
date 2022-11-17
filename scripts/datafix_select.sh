#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
export TARGET_ENV_SHORT=$TARGET_ENV_SHORT
export PODMAN_WORKDIR=$PODMAN_WORKDIR

podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/$PODMAN_WORKDIR \
  --workdir $PODMAN_WORKDIR \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_LIQUBASE \
  --defaultsFile=liquibase.properties --sql-file=scripts/datafix_select.sql execute-sql

DATAFIX_RC=\$?

# Two exits are required because we are running as another user
# Only send email for prod
if [ \$DATAFIX_RC -ne 0 ]; then
  if [ "$TARGET_ENV" = "production" ]; then
    echo "${BUILD_URL}" | mailx -s "Error during Liquibase datafix select" NRIDS.ApplicationDelivery@gov.bc.ca
  fi
  exit \$DATAFIX_RC
  exit \$DATAFIX_RC
fi
EOF
