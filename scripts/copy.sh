#!/usr/bin/env bash

cp scripts/config.hcl $TMP_VOLUME
tar -C $TMP_VOLUME -zcf $TMP_VOLUME.tar.gz .

set +x
sshpass -p $CD_PASS scp -q $TMP_VOLUME.tar.gz $CD_USER@$HOST:/tmp 
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER
mkdir /tmp/$TMP_VOLUME
tar -xf /tmp/$TMP_VOLUME.tar.gz -C /tmp/$TMP_VOLUME
EOF

# clean up
rm $TMP_VOLUME.tar.gz
