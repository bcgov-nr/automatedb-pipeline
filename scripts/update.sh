#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
export TAG_VERSION=$TAG_VERSION
export PODMAN_WORKDIR=$PODMAN_WORKDIR
# Run update
podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/$PODMAN_WORKDIR \
  --workdir $PODMAN_WORKDIR \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_LIQUBASE \
  --defaultsFile=liquibase.properties update

UPDATE_RC=\$?

# Two exits are required because we are running as another user
if [ \$UPDATE_RC -ne 0 ] && [ "$TARGET_ENV" = "production" ]; then
  echo "${BUILD_URL}" | mailx -s "Error during Liquibase update" NRIDS.ApplicationDelivery@gov.bc.ca
  exit \$UPDATE_RC
  exit \$UPDATE_RC
fi

# Tag version
podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/$PODMAN_WORKDIR \
  --workdir $PODMAN_WORKDIR \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_LIQUBASE \
  --defaultsFile=liquibase.properties tag $TAG_VERSION

TAG_RC=\$?

# Two exits are required because we are running as another user
# Only send email for prod
if [ \$TAG_RC -ne 0 ]; then
  if [ "$TARGET_ENV" = "production" ]; then
    echo "${BUILD_URL}" | mailx -s "Error during Liquibase tagging" NRIDS.ApplicationDelivery@gov.bc.ca
  fi
  exit \$TAG_RC
  exit \$TAG_RC
fi
EOF
