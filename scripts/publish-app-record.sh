#!/bin/bash

set -e

RECORD_FILE=tmp.rf.$$
CONFIG_FILE=`mktemp`

CERC_APP_TYPE=${CERC_APP_TYPE:-"webapp/next"}
CERC_REPO_REF=${CERC_REPO_REF:-${GITHUB_SHA:-`git log -1 --format="%H"`}}
CERC_IS_LATEST_RELEASE=${CERC_IS_LATEST_RELEASE:-"true"}

rcd_name=$(jq -r '.name' package.json | sed 's/null//')
rcd_desc=$(jq -r '.description' package.json | sed 's/null//')
rcd_repository=$(jq -r '.repository' package.json | sed 's/null//')
rcd_homepage=$(jq -r '.homepage' package.json | sed 's/null//')
rcd_license=$(jq -r '.license' package.json | sed 's/null//')
rcd_author=$(jq -r '.author' package.json | sed 's/null//')
rcd_app_version=$(jq -r '.version' package.json | sed 's/null//')

cat <<EOF > "$CONFIG_FILE"
services:
  registry:
    rpcEndpoint: '${CERC_REGISTRY_RPC_ENDPOINT:-http://testnet-a-1.dev.vaasl.io:26657}'
    gqlEndpoint: '${CERC_REGISTRY_GQL_ENDPOINT:-http://testnet-a-1.dev.vaasl.io:9473/api}'
    chainId: ${CERC_REGISTRY_CHAIN_ID:-laconic-08062024}
    gas: 900000
    fees: 900000alnt
EOF

next_ver=$(laconic -c $CONFIG_FILE registry record list --type ApplicationRecord --all --name "$rcd_name" 2>/dev/null | jq -r -s ".[] | sort_by(.createTime) | reverse | [ .[] | select(.bondId == \"$CERC_REGISTRY_BOND_ID\") ] | .[0].attributes.version" | awk -F. -v OFS=. '{$NF += 1 ; print}')

if [ -z "$next_ver" ] || [ "1" == "$next_ver" ]; then
  next_ver=0.0.1
fi

cat <<EOF | sed '/.*: ""$/d' > "$RECORD_FILE"
record:
  type: ApplicationRecord
  version: ${next_ver}
  name: "$rcd_name"
  description: "$rcd_desc"
  homepage: "$rcd_homepage"
  license: "$rcd_license"
  author: "$rcd_author"
  repository:
    - "$rcd_repository"
  repository_ref: "$CERC_REPO_REF"
  app_version: "$rcd_app_version"
  app_type: "$CERC_APP_TYPE"
EOF


cat $RECORD_FILE
RECORD_ID=$(laconic -c $CONFIG_FILE registry record publish --filename $RECORD_FILE --user-key "${CERC_REGISTRY_USER_KEY}" --bond-id ${CERC_REGISTRY_BOND_ID} | jq -r '.id')
echo $RECORD_ID

if [ -z "$CERC_REGISTRY_APP_LRN" ]; then
  authority=$(echo "$rcd_name" | cut -d'/' -f1 | sed 's/@//')
  app=$(echo "$rcd_name" | cut -d'/' -f2-)
  CERC_REGISTRY_APP_LRN="lrn://$authority/applications/$app"
fi

laconic -c $CONFIG_FILE registry name set --user-key "${CERC_REGISTRY_USER_KEY}" --bond-id ${CERC_REGISTRY_BOND_ID} "$CERC_REGISTRY_APP_LRN@${rcd_app_version}" "$RECORD_ID"
laconic -c $CONFIG_FILE registry name set --user-key "${CERC_REGISTRY_USER_KEY}" --bond-id ${CERC_REGISTRY_BOND_ID} "$CERC_REGISTRY_APP_LRN@${CERC_REPO_REF}" "$RECORD_ID"
if [ "true" == "$CERC_IS_LATEST_RELEASE" ]; then
  laconic -c $CONFIG_FILE registry name set --user-key "${CERC_REGISTRY_USER_KEY}" --bond-id ${CERC_REGISTRY_BOND_ID} "$CERC_REGISTRY_APP_LRN" "$RECORD_ID"
fi

rm -f $RECORD_FILE $CONFIG_FILE
