#!/bin/sh
set +x
echo "Temp directory: /tmp/$TMP_DIR"
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $INSTALL_USER
mkdir /tmp/$TMP_DIR
chmod 777 /tmp/$TMP_DIR
exit
mkdir /tmp/$TMP_DIR/migrations
chmod 755 /tmp/$TMP_DIR/migrations
EOF

sshpass -p $CD_PASS scp -q $TMP_DIR/* $CD_USER@$HOST:/tmp/$TMP_DIR
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
chmod -R 755 /tmp/$TMP_DIR/* 
EOF