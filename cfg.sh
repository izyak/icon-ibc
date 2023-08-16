#!/bin/bash

source const.sh
source utils.sh


BACKUP_RLY_CFG_FILE=$HOME/.relayer/config/config_backup.yaml
KEY_DIR=$HOME/.relayer/keys

mkdir -p $KEY_DIR/ibc-icon
cp $ICON_WALLET $KEY_DIR/ibc-icon/

wasm_ibc=$(cat $CONTRACT_ADDR_WASM_IBC_CORE)
icon_ibc=$(cat $CONTRACT_ADDR_JAVA_IBC_CORE)

btp_network_id=$(goloop rpc btpnetworktype --uri $ICON_NODE 0x1 | jq -r '.openNetworkIDs[-1]')

cp $RELAY_CFG $BACKUP_RLY_CFG_FILE
rm $RELAY_CFG

cat <<EOF >> $RELAY_CFG
global:
  api-listen-addr: :5183
  timeout: 10s
  memo: ""
  light-cache-size: 20
chains:
  archway:
    type: wasm
    value:
      key-directory: $KEY_DIR 
      key: $WASM_RELAY_WALLET
      chain-id: $WASM_CHAIN_ID
      rpc-addr: $WASM_NODE
      account-prefix: $WASM_PREFIX
      keyring-backend: test
      gas-adjustment: 1.5
      gas-prices: $WASM_GAS$WASM_TOKEN
      min-gas-amount: 1_000_000
      debug: true
      timeout: 20s
      block-timeout: ""
      output-format: json
      sign-mode: direct
      extra-codecs: []
      coin-type: 0
      broadcast-mode: batch
      ibc-handler-address: $wasm_ibc
      start-height: 0
      block-interval: 3000
  icon:
    type: icon
    value:
      key-directory: $KEY_DIR 
      chain-id: ibc-icon
      rpc-addr: $ICON_NODE
      timeout: 30s
      keystore: $ICON_WALLET_NAME 
      password: $ICON_RELAY_PASSWORD
      icon-network-id: $ICON_NID
      btp-network-id: $(hex2dec $btp_network_id)
      btp-network-type-id: 1
      start-btp-height: 0
      ibc-handler-address: $icon_ibc
      start-height: 0
      block-interval: 2000
paths:
  $RELAY_PATH_NAME:
    src:
      chain-id: ibc-icon
    dst:
      chain-id: $WASM_CHAIN_ID
    src-channel-filter:
      rule: ""
      channel-list: []
EOF

log "relay config updated!"