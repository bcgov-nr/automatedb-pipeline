#!/bin/sh
set +x
echo "Temp directory: /tmp/$TMP_VOLUME"
echo "Temp output file: /tmp/$TMP_OUTPUT_FILE"
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
rm /tmp/$TMP_VOLUME.tar.gz
sudo -su $PODMAN_USER
rm -r /tmp/$TMP_VOLUME
rm -f /tmp/$TMP_OUTPUT_FILE
EOF
