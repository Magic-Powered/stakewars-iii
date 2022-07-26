#!/bin/bash
set -e

VALIDATOR_INDEX=${HOSTNAME##*-}
NEAR_HOME=${NEAR_HOME:-/srv/near}
VALIDATOR_KEY=validator_key.json
NODE_KEY=node_key.json

export NEAR_HOME

echo "Setup keys for validator $VALIDATOR_INDEX"

declare NODE_ACCOUNT_ID=NODE_${VALIDATOR_INDEX}_ACCOUNT_ID
declare NODE_PUBLIC_KEY=NODE_${VALIDATOR_INDEX}_PUBLIC_KEY
declare NODE_SECRET_KEY=NODE_${VALIDATOR_INDEX}_SECRET_KEY

declare VALIDATOR_ACCOUNT_ID=VALIDATOR_${VALIDATOR_INDEX}_ACCOUNT_ID
declare VALIDATOR_PUBLIC_KEY=VALIDATOR_${VALIDATOR_INDEX}_PUBLIC_KEY
declare VALIDATOR_SECRET_KEY=VALIDATOR_${VALIDATOR_INDEX}_SECRET_KEY

cat << EOF > "$NEAR_HOME/$NODE_KEY"
{"account_id": "`printenv $NODE_ACCOUNT_ID`", "public_key": "`printenv $NODE_PUBLIC_KEY`", "secret_key": "`printenv $NODE_SECRET_KEY`"}
EOF
cat << EOF > "$NEAR_HOME/$VALIDATOR_KEY"
{"account_id": "`printenv $VALIDATOR_ACCOUNT_ID`", "public_key": "`printenv $VALIDATOR_PUBLIC_KEY`", "secret_key": "`printenv $VALIDATOR_SECRET_KEY`"}
EOF

if [ ! -f "$NEAR_HOME/genesis.json" ]; then
  echo "Downloading genesis json snapshot..."
  wget https://s3-us-west-1.amazonaws.com/build.nearprotocol.com/nearcore-deploy/shardnet/genesis.json.xz -P $NEAR_HOME
  echo "Extracting chain genesis..."
  xz -d $NEAR_HOME/genesis.json.xz
else
  echo "Genesis file already exist. Skipping genesis restoring."
fi

# if [ ! -d "$NEAR_HOME/data" ]; then
#   echo "Downloading chain snapshot..."
#   aws s3 --no-sign-request cp s3://build.openshards.io/stakewars/shardnet/data.tar.gz $NEAR_HOME
#   echo "Extracting chain snapshot..."
#   tar -xzvf $NEAR_HOME/data.tar.gz -C $NEAR_HOME
#   echo "Remove snapshot..."
#   rm -f $NEAR_HOME/data.tar.gz
# else
#   echo "Chain data path exist. Skipping snapshot restoring."
# fi

ulimit -c unlimited

exec neard run "$@"
