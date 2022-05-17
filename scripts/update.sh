#!/usr/bin/env bash

# cd "${0%/*}/../db"

# # Display status
# liquibase status

# # Perform application migration for version ${ VERSION }
# liquibase update -Dapp_version=${VERSION}

# # Tag database for version ${ VERSION }
# liquibase tag ${VERSION}
sshpass -p $CD_PASS ssh $CD_USER@$HOST /bin/bash <<EOF
sudo -su $INSTALL_USER
podman run --network="host" --rm -v /tmp/$TMP_DIR:/liquibase/changelog liquibase/liquibase --defaultsFile=changelog/liquibase.properties update
EOF