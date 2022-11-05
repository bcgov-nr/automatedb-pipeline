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
  --defaultsFile=liquibase.properties --sql-file=scripts/datafix_select.sh execute-sql
EOF
