#!/bin/sh
set +x
echo "Temp directory: /tmp/$TMP_DIR"
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $INSTALL_USER
podman run --network="host" --rm -v /tmp/$TMP_DIR:/liquibase/changelog liquibase/liquibase --defaultsFile=changelog/liquibase.properties update
EOF
