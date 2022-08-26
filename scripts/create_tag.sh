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

# Set tag name
if [ "$TARGET_ENV" = "dev" ]; then
 declare +i -r TAG_NAME="$TAG_VERSION-dev"
elif [ "$TARGET_ENV" = "test" ]; then
  declare +i -r TAG_NAME="$TAG_VERSION-test"
elif [ "$TARGET_ENV" = "prod" ]; then
  declare +i -r TAG_NAME="$TAG_VERSION"
else
  echo "Invalid target environment for tagging. Stop execution."
  exit 1
  exit 1
fi

get_tag_display_id() {
  local TAG_NAME_LOCAL="\$1"
  curl -s --request GET \
    -u "$CI_USER:$CI_PASS" \
    --url "https://$BITBUCKET_BASEURL/rest/api/1.0/projects/$PROJECT_KEY/repos/$DB_COMPONENT/tags/\$TAG_NAME_LOCAL" \
    --header 'Accept: application/json' | /sw_ux/bin/jq '.displayId' | sed 's/\"//g'
}

delete_tag() {
  local TAG_NAME_LOCAL="\$1"
  curl -s --request DELETE \
    -u "$CI_USER:$CI_PASS" \
    --url "https://$BITBUCKET_BASEURL/rest/git/1.0/projects/$PROJECT_KEY/repos/$DB_COMPONENT/tags/\$TAG_NAME_LOCAL" \
    --header 'Accept: application/json'
}

get_commit_id_main() {
  curl -s --request GET \
    -u "${CI_USER}:${CI_PASS}" \
    --url "https://$BITBUCKET_BASEURL/rest/api/1.0/projects/$PROJECT_KEY/repos/$DB_COMPONENT/commits?until=main&limit=1" \
    --header 'Accept: application/json' | /sw_ux/bin/jq '.values[0].id'
}

get_commit_id_tag() {
  local TAG_NAME_LOCAL="\$1"
  curl -s --request GET \
    -u "${CI_USER}:${CI_PASS}" \
    --url "https://$BITBUCKET_BASEURL/rest/api/1.0/projects/$PROJECT_KEY/repos/$DB_COMPONENT/tags/\$TAG_NAME_LOCAL" \
    --header 'Accept: application/json' | /sw_ux/bin/jq '.latestCommit'
}

# Delete non-prod tags if they exist
# https://stackoverflow.com/questions/43582768/delete-request-on-stash-tags
if [ "$TARGET_ENV" = "dev" ] || [ "$TARGET_ENV" = "test" ]; then
  TAG_DISPLAY_ID=\$(get_tag_display_id "\$TAG_NAME")
  if [ "\$TAG_DISPLAY_ID" = "\$TAG_NAME" ]; then
    echo "Delete tag \$TAG_NAME"
    delete_tag "\$TAG_NAME"
  fi
fi

# Get commit id for tag creation
if [ "$TARGET_ENV" = "dev" ]; then
  COMMIT_ID=\$(get_commit_id_main)
fi

if [ "$TARGET_ENV" = "test" ]; then
  COMMIT_ID=\$(get_commit_id_tag "$TAG_VERSION-dev")
fi

if [ "$TARGET_ENV" = "prod" ]; then
  COMMIT_ID=\$(get_commit_id_tag "$TAG_VERSION-test")
fi

# Generate post data for tag creation
generate_post_data() {
  cat <<EOT
{
  "message": "Tag created by $CI_USER",
  "name": "\$TAG_NAME",
  "startPoint": \$COMMIT_ID
}
EOT
}

# Create tag
echo "Create tag \$TAG_NAME"
curl -s --request POST \
  -u "$CI_USER:$CI_PASS" \
  --url "https://$BITBUCKET_BASEURL/rest/api/1.0/projects/$PROJECT_KEY/repos/$DB_COMPONENT/tags" \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data "\$(generate_post_data)"

# Delete non-prod tags after prod deployment
if [ "$TARGET_ENV" = "prod" ]; then
  delete_tag "$TAG_VERSION-dev"
  delete_tag "$TAG_VERSION-test"
fi
EOF
