#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
export TAG_VERSION=$TAG_VERSION
export PODMAN_WORKDIR=$PODMAN_WORKDIR
# Run update
podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/liquibase/changelog \
  --workdir $PODMAN_WORKDIR \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_LIQUBASE \
  --defaultsFile=liquibase.properties update-sql
EOF
