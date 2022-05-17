#!/bin/sh
set +x
echo "Temp directory: /tmp/$TMP_DIR"
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
rm -rf /tmp/$TMP_DIR/migrations
rm -rf /tmp$TMP_DIR/changelog.xml
rm -rf /tmp/$TMP_DIR/liquibase.properties
sudo -su $INSTALL_USER
rm -rf /tmp/$TMP_DIR
EOF
