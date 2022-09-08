#!/usr/bin/env bash
set +x
sshpass -p $CD_PASS ssh -q $CD_USER@$HOST /bin/bash <<EOF
sudo -su $PODMAN_USER

# Command alias
# https://serverfault.com/questions/849947/execute-local-alias-through-ssh-on-remote-server
shopt -s expand_aliases
alias curl="podman run --rm \
  --security-opt label=disable \
  -v /sw_ux/bin:/sw_ux/bin \
  -e CI_USER=$CI_USER \
  -e CI_PASS=$CI_PASS \
  -e BITBUCKET_BASEURL=$BITBUCKET_BASEURL \
  -e PROJECT_KEY=$PROJECT_KEY \
  -e DB_COMPONENT=$DB_COMPONENT \
  -e TAG_VERSION=$TAG_VERSION \
  $PODMAN_REGISTRY/$CONTAINER_IMAGE_CURL"

# Check tag
RETURN_VALUE=\$(curl -s --request GET \
  -u "$CI_USER:$CI_PASS" \
  --url "https://$BITBUCKET_BASEURL/rest/api/1.0/projects/$PROJECT_KEY/repos/$DB_COMPONENT/tags/$TAG_VERSION" \
  --header 'Accept: application/json' | /sw_ux/bin/jq '.displayId' | sed 's/\"//g')

# Exit if tag exists
# Two exits are needed because we are connecting as the CD user and running as the podman user
# The CD user has to exit 1 for Jenkins to recognize the error code  
if [ "\$RETURN_VALUE" = "$TAG_VERSION" ]; then
  echo "Tag $TAG_VERSION exists. Stop execution."
  exit 1
  exit 1
else
  echo "Tag $TAG_VERSION does not exist. Continue execution."
fi
EOF
