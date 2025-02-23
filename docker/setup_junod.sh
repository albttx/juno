#!/bin/sh
#set -o errexit -o nounset -o pipefail

PASSWORD=${PASSWORD:-1234567890}
STAKE=${STAKE_TOKEN:-ustake}
FEE=${FEE_TOKEN:-ucosm}
CHAIN_ID=${CHAIN_ID:-testing}
MONIKER=${MONIKER:-node001}
KEYRING="--keyring-backend test"

junod init --chain-id "$CHAIN_ID" "$MONIKER"
# staking/governance token is hardcoded in config, change this
sed -i "s/\"stake\"/\"$STAKE\"/" "$HOME"/.juno/config/genesis.json
# this is essential for sub-1s block times (or header times go crazy)
sed -i 's/"time_iota_ms": "1000"/"time_iota_ms": "10"/' "$HOME"/.juno/config/genesis.json
# change default keyring-backend to test
sed -i 's/keyring-backend = "os"/keyring-backend = "test"/' "$HOME"/.juno/config/client.toml

if ! junod keys show validator $KEYRING; then
  (echo "$PASSWORD"; echo "$PASSWORD") | junod keys add validator $KEYRING
fi
# hardcode the validator account for this instance
echo "$PASSWORD" | junod add-genesis-account validator "1000000000$STAKE,1000000000$FEE" $KEYRING

# (optionally) add a few more genesis accounts
for addr in "$@"; do
  echo $addr
  junod add-genesis-account "$addr" "1000000000$STAKE,1000000000$FEE"
done

# submit a genesis validator tx
## Workraround for https://github.com/cosmos/cosmos-sdk/issues/8251
(echo "$PASSWORD"; echo "$PASSWORD"; echo "$PASSWORD") | junod gentx validator "250000000$STAKE" --chain-id="$CHAIN_ID" --amount="250000000$STAKE" $KEYRING
## should be:
# (echo "$PASSWORD"; echo "$PASSWORD"; echo "$PASSWORD") | junod gentx validator "250000000$STAKE" --chain-id="$CHAIN_ID"
junod collect-gentxs
