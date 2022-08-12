#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
export VERSION=$VERSION
# Run update
podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/liquibase/changelog \
  --workdir src/cd/migrations/csd_web \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_LIQUBASE \
  --defaultsFile=liquibase.properties update-sql
# Tag version
podman run --rm \
  --security-opt label=disable \
  -v /tmp/$TMP_VOLUME:/liquibase/changelog \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_LIQUBASE \
  --defaultsFile=liquibase.properties tag ${VERSION}
EOF
