#!/bin/bash

export COSMOS=archway 		## [ neutron, archway ]
export COSMOS_NET=testnet 	## [ local, testnet ]
export ICON=icon
export ICON_NET=berlin 		## [ goloop, berlin, lisbon]

#################################################################################
##############################     CHANGE     ###################################
#################################################################################

export IBC_RELAY=$HOME/ibc-relay
export IBC_INTEGRATION=$HOME/IBC-Integration

export ICON_DOCKER_PATH=$HOME/gochain-btp
export WASM_DOCKER_PATH=$HOME/archway

export COSMOS_CONTRACT_ADDR_LEN=66
export ICON_CONTRACT_ADDR_LEN=42

export KEYSTORE=$PWD/keystore

export ICON_IBC_WALLET_NAME=ibc_wallet
export ICON_XCALL_WALLET_NAME=xcall_wallet
export ICON_RELAY_WALLET_NAME=relay_wallet

export ICON_IBC_WALLET=$KEYSTORE/${ICON_IBC_WALLET_NAME}.json
export ICON_XCALL_WALLET=$KEYSTORE/${ICON_XCALL_WALLET_NAME}.json
export ICON_RELAY_WALLET=$KEYSTORE/${ICON_RELAY_WALLET_NAME}.json

export ICON_IBC_PASSWORD_FILE=$KEYSTORE/${ICON_IBC_WALLET_NAME}_password.txt
export ICON_XCALL_PASSWORD_FILE=$KEYSTORE/${ICON_XCALL_WALLET_NAME}_password.txt
export ICON_RELAY_PASSWORD_FILE=$KEYSTORE/${ICON_RELAY_WALLET_NAME}_password.txt

export ICON_IBC_PASSWORD=$(cat $ICON_IBC_PASSWORD_FILE) > /dev/null
export ICON_XCALL_PASSWORD=$(cat $ICON_XCALL_PASSWORD_FILE) > /dev/null
export ICON_RELAY_PASSWORD=$(cat $ICON_RELAY_PASSWORD_FILE) > /dev/null

export WASM_IBC_WALLET=ibc_wallet
export WASM_XCALL_WALLET=xcall_wallet
export WASM_RELAY_WALLET=relay_wallet

export WASM_EXTRA=" " # "-keyring-backend test"
export WASM_BIN=archwayd

export ICON_PORT_ID="xcall"
export WASM_PORT_ID="xcall"

export RELAY_CFG=$HOME/.relayer/config/config.yaml
export RELAY_PATH_NAME=icon-archway

#################################################################################
##############################    NETWORKS    ###################################
#################################################################################
case $COSMOS in 
	"archway" )
		if [[ $COSMOS_NET == "local" ]]; then
			export WASM_NODE=http://localhost:26657
			export WASM_CHAIN_ID=localnet
			export WASM_TOKEN=stake
			export WASM_GAS=0.025
			export WASM_NETWORK_ID=archway
			export WASM_PREFIX=archway
		elif [[ $COSMOS_NET == "testnet" ]]; then 
			export WASM_NODE=https://rpc.constantine.archway.tech:443
			export WASM_CHAIN_ID=constantine-3
			export WASM_TOKEN=aconst
			export WASM_GAS=900000000000
			export WASM_NETWORK_ID=archway
			export WASM_PREFIX=archway
		else
			echo "Invalid cosmos chain selected. Ensure COSMOS_NET = local or testnet "
			exit 0
		fi
	;;
	"neutron" )
		if [[ $COSMOS_NET == "local" ]]; then
			export WASM_NODE=http://localhost:26657
			export WASM_CHAIN_ID=test-1
			export WASM_TOKEN=stake
			export WASM_GAS=0.025
			export WASM_NETWORK_ID=neutron
			export WASM_PREFIX=neutron
		elif [[ $COSMOS_NET == "testnet" ]]; then 
			export WASM_NODE=https://rpc.constantine.archway.tech:443
			export WASM_CHAIN_ID=pion-1
			export WASM_TOKEN=untrn
			export WASM_GAS=900000000000
			export WASM_NETWORK_ID=neutron
			export WASM_PREFIX=neutron
		else
			echo "Invalid cosmos chain selected. Ensure COSMOS_NET = local or testnet "
			exit 0
		fi
	;;
esac

export WASM_IBC_COMMON_ARGS=" --from ${WASM_IBC_WALLET} ${WASM_EXTRA} --node ${WASM_NODE} --chain-id ${WASM_CHAIN_ID} --gas-prices ${WASM_GAS}${WASM_TOKEN} --gas auto --gas-adjustment 1.5  "
export WASM_XCALL_COMMON_ARGS=" --from ${WASM_XCALL_WALLET} ${WASM_EXTRA} --node ${WASM_NODE} --chain-id ${WASM_CHAIN_ID} --gas-prices ${WASM_GAS}${WASM_TOKEN} --gas auto --gas-adjustment 1.5  "

case $ICON_NET in 
	"goloop" )
		export ICON_NID=3
		export ICON_CHAIN_ID=goloop
		export ICON_NODE=http://localhost:9082/api/v3/
		export ICON_DEBUG_NODE=http://localhost:9082/api/v3d
		export ICON_NETWORK_ID="0x3.icon"
	;;
	"berlin" )
		export ICON_NID=7
		export ICON_CHAIN_ID=berlin
		export ICON_NODE=https://berlin.net.solidwallet.io/api/v3/
		export ICON_DEBUG_NODE=https://berlin.net.solidwallet.io/api/v3d
		export ICON_NETWORK_ID="0x7.icon"
	;;
	"lisbon" )
		export ICON_NID=2
		export ICON_CHAIN_ID=lisbon
		export ICON_NODE=https://lisbon.net.solidwallet.io/api/v3/
		export ICON_DEBUG_NODE=https://lisbon.net.solidwallet.io/api/v3d
		export ICON_NETWORK_ID="0x2.icon"
	;;
esac

export ICON_IBC_COMMON_ARGS="--uri $ICON_NODE --nid $ICON_NID --step_limit 100000000000 --key_store $ICON_IBC_WALLET --key_password $ICON_IBC_PASSWORD "
export ICON_XCALL_COMMON_ARGS="--uri $ICON_NODE --nid $ICON_NID --step_limit 100000000000 --key_store $ICON_XCALL_WALLET --key_password $ICON_XCALL_PASSWORD "
#################################################################################

export JAVASCORE_DIR=$IBC_INTEGRATION/artifacts/icon
export WASM_DIR=$IBC_INTEGRATION/artifacts/archway
export SCRIPTS_DIR=$PWD

export CONTRACT_ADDRESS_FOLDER=$SCRIPTS_DIR/env
export WASM_ADDRESSES=$CONTRACT_ADDRESS_FOLDER/$COSMOS
export ICON_ADDRESSES=$CONTRACT_ADDRESS_FOLDER/$ICON
export ARTIFACTS=$PWD/artifacts
export LOGS=$PWD/ixc

#################################################################################
#########################     WASM CONTRACTS     ################################
#################################################################################

export CONTRACT_FILE_WASM_IBC_CORE=$ARTIFACTS/cw_ibc_core.wasm
export CONTRACT_FILE_WASM_LIGHT_CLIENT=$ARTIFACTS/cw_icon_light_client.wasm
export CONTRACT_FILE_WASM_XCALL_CONNECTION=$ARTIFACTS/cw_xcall_connection.wasm
export CONTRACT_FILE_WASM_XCALL=$ARTIFACTS/cw_xcall.wasm

export CONTRACT_ADDR_WASM_IBC_CORE=$WASM_ADDRESSES/.ibcCore
export CONTRACT_ADDR_WASM_LIGHT_CLIENT=$WASM_ADDRESSES/.lightClient
export CONTRACT_ADDR_WASM_XCALL_CONNECTION=$WASM_ADDRESSES/.xcallConnection
export CONTRACT_ADDR_WASM_XCALL=$WASM_ADDRESSES/.xcall

#################################################################################
#########################     JAVA CONTRACTS     ################################
#################################################################################

export CONTRACT_FILE_JAVA_IBC_CORE=$ARTIFACTS/ibc.jar
export CONTRACT_FILE_JAVA_LIGHT_CLIENT=$ARTIFACTS/tendermint.jar
export CONTRACT_FILE_JAVA_XCALL_CONNECTION=$ARTIFACTS/xcall_connection.jar
export CONTRACT_FILE_JAVA_XCALL=$ARTIFACTS/xcall.jar

export CONTRACT_ADDR_JAVA_IBC_CORE=$ICON_ADDRESSES/.ibcCore
export CONTRACT_ADDR_JAVA_LIGHT_CLIENT=$ICON_ADDRESSES/.lightClient
export CONTRACT_ADDR_JAVA_XCALL_CONNECTION=$ICON_ADDRESSES/.xcallConnection
export CONTRACT_ADDR_JAVA_XCALL=$ICON_ADDRESSES/.xcall

export GOVERNANCE_SCORE=cx0000000000000000000000000000000000000001


#################################################################################
####################  CREATE REQD DIRECTORY IF NOT EXISTS #######################
#################################################################################
mkdir -p $WASM_ADDRESSES
mkdir -p $ICON_ADDRESSES
mkdir -p $LOGS
mkdir -p $KEYSTORE
