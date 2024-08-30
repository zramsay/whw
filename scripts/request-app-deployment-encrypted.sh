#!/bin/bash

set -e

CONFIG_FILE=`mktemp`
ENV_FILE=`mktemp`

rcd_name=$(jq -r '.name' package.json | sed 's/null//' | sed 's/^@//')
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

if [ -z "$CERC_REGISTRY_APP_LRN" ]; then
  authority=$(echo "$rcd_name" | cut -d'/' -f1 | sed 's/@//')
  app=$(echo "$rcd_name" | cut -d'/' -f2-)
  CERC_REGISTRY_APP_LRN="lrn://$authority/applications/$app"
fi

cat >$ENV_FILE <<EOF
CERC_TEST_WEBAPP_CONFIG1="this is an encrypted string"
CERC_TEST_WEBAPP_CONFIG2="this is also an encrypted string"
CERC_WEBAPP_DEBUG="$CERC_REGISTRY_APP_LRN - CRYPT"
EOF

laconic-so request-webapp-deployment \
  --laconic-config $CONFIG_FILE \
  --deployer $CERC_REGISTRY_DEPLOYER_LRN \
  --app $CERC_REGISTRY_APP_LRN \
  --env-file $ENV_FILE \
  --make-payment auto

rm -f $ENV_FILE $CONFIG_FILE
