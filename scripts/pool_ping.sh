#!/bin/bash
set -e

VALIDATOR_INDEX=${HOSTNAME##*-}
NEAR_HOME=${NEAR_HOME:-/srv/near}
NEAR_CLI_HOME=~/.near-credentials/shardnet
CRONJOB=/etc/cron.d/ping-pool
CRONLOG=/var/log/cron.log
NODE_URL=http://127.0.0.1:3030 

export NEAR_HOME
mkdir -p $NEAR_CLI_HOME

echo "Setup keys for wallet $VALIDATOR_INDEX"

declare WALLET_ACCOUNT_ID=WALLET_${VALIDATOR_INDEX}_ACCOUNT_ID
declare WALLET_PUBLIC_KEY=WALLET_${VALIDATOR_INDEX}_PUBLIC_KEY
declare WALLET_PRIVATE_KEY=WALLET_${VALIDATOR_INDEX}_PRIVATE_KEY
declare WALLET_FILE=$NEAR_CLI_HOME/`printenv $WALLET_ACCOUNT_ID`.json
declare WALLET_NAME=`printenv $WALLET_ACCOUNT_ID | cut -d. -f1`

cat << EOF > "$WALLET_FILE"
{"account_id": "`printenv $WALLET_ACCOUNT_ID`", "public_key": "`printenv $WALLET_PUBLIC_KEY`", "private_key": "`printenv $WALLET_PRIVATE_KEY`"}
EOF

echo "Setup cronjob for pool ping"

touch ${CRONLOG}
cat << EOF > "${CRONJOB}"
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
NEAR_ENV=shardnet
*/5 * * * * /usr/local/bin/near call ${WALLET_NAME}.factory.shardnet.near ping '{}' --nodeUrl ${NODE_URL} --accountId `printenv $WALLET_ACCOUNT_ID` --gas=300000000000000 >> ${CRONLOG} 2>&1
*/6 * * * * /usr/local/bin/near proposals | grep ${WALLET_NAME} >> ${CRONLOG} 2>&1
*/7 * * * * /usr/local/bin/near validators current | grep ${WALLET_NAME} >> ${CRONLOG} 2>&1
*/8 * * * * /usr/local/bin/near validators next | grep ${WALLET_NAME} >> ${CRONLOG} 2>&1
EOF

crontab ${CRONJOB}

echo "Start crontab and waiting for logs..."
cron && tail -f ${CRONLOG}