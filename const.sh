#!/bin/bash

export COSMOS=archway 		## [ neutron, cosmos ]
export COSMOS_NET=local 	## [ local, testnet ]
export ICON=icon
export ICON_NET=goloop 		## [ goloop, testnet]


#################################################################################
##############################     CHANGE     ###################################
#################################################################################

export IBC_RELAY=$HOME/ibriz/ibc/ibc-relay
export IBC_INTEGRATION=$HOME/ibriz/ibc/IBC-Integration

export ICON_DOCKER_PATH=$HOME/gochain-btp
export WASM_DOCKER_PATH=$HOME/archway

export ICON_WALLET_NAME=godWallet
export ICON_WALLET=$HOME/keystore/${ICON_WALLET_NAME}.json
export ICON_PASSWORD=gochain

export WASM_WALLET=godWallet
export WASM_EXTRA=" " # "-keyring-backend test"
export WASM_BIN=archwayd

export ICON_PORT_ID="xcall"
export WASM_PORT_ID="xcall"

export RELAY_CFG=$HOME/.relayer/config/config.yaml

# use same addr to deploy contracts and relay
export ICON_RELAY_WALLET=$ICON_WALLET
export ICON_RELAY_PASSWORD=$ICON_PASSWORD

export WASM_RELAY_WALLET=relayWallet

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

export WASM_COMMON_ARGS=" --from ${WASM_WALLET} ${WASM_EXTRA} --node ${WASM_NODE} --chain-id ${WASM_CHAIN_ID} --gas-prices ${WASM_GAS}${WASM_TOKEN} --gas auto --gas-adjustment 1.3  "

case $ICON_NET in 
	"goloop" )
		export ICON_NID=3
		export ICON_SLEEP_TIME=2
		export ICON_NODE=http://localhost:9082/api/v3/
		export ICON_DEBUG_NODE=http://localhost:9082/api/v3d
		export ICON_NETWORK_ID="0x3.icon"
	;;
	"testnet" )
		export ICON_NID=7
		export ICON_SLEEP_TIME=8
		export ICON_NODE=https://berlin.net.solidwallet.io/api/v3/
		export ICON_DEBUG_NODE=https://berlin.net.solidwallet.io/api/v3d
		export ICON_NETWORK_ID="0x7.icon"
	;;
esac

export ICON_COMMON_ARGS="--uri $ICON_NODE --nid $ICON_NID --step_limit 100000000000 --key_store $ICON_WALLET --key_password $ICON_PASSWORD "
#################################################################################

export JAVASCORE_DIR=$IBC_INTEGRATION/artifacts/icon
export WASM_DIR=$IBC_INTEGRATION/artifacts/archway
export SCRIPTS_DIR=$PWD

export CONTRACT_ADDRESS_FOLDER=$SCRIPTS_DIR/env
export WASM_ADDRESSES=$CONTRACT_ADDRESS_FOLDER/$COSMOS
export ICON_ADDRESSES=$CONTRACT_ADDRESS_FOLDER/$ICON
export BTP_NETWORK_ID=$CONTRACT_ADDRESS_FOLDER/.btpNetworkId

#################################################################################
#########################     WASM CONTRACTS     ################################
#################################################################################

export CONTRACT_FILE_WASM_IBC_CORE=$WASM_DIR/cw_ibc_core.wasm
export CONTRACT_FILE_WASM_LIGHT_CLIENT=$WASM_DIR/cw_icon_light_client.wasm
export CONTRACT_FILE_WASM_XCALL_CONNECTION=$WASM_DIR/cw_xcall_ibc_connection.wasm
export CONTRACT_FILE_WASM_XCALL=$WASM_DIR/cw_xcall.wasm
export CONTRACT_FILE_WASM_XCALL_DAPP=$WASM_DIR/cw_mock_dapp_multi.wasm

export CONTRACT_ADDR_WASM_IBC_CORE=$WASM_ADDRESSES/.ibcCore
export CONTRACT_ADDR_WASM_LIGHT_CLIENT=$WASM_ADDRESSES/.lightClient
export CONTRACT_ADDR_WASM_XCALL_CONNECTION=$WASM_ADDRESSES/.xcallConnection
export CONTRACT_ADDR_WASM_XCALL=$WASM_ADDRESSES/.xcall
export CONTRACT_ADDR_WASM_XCALL_DAPP=$WASM_ADDRESSES/.xcallDapp

#################################################################################
#########################     JAVA CONTRACTS     ################################
#################################################################################

export CONTRACT_FILE_JAVA_IBC_CORE=$JAVASCORE_DIR/ibc-0.1.0-optimized.jar
export CONTRACT_FILE_JAVA_LIGHT_CLIENT=$JAVASCORE_DIR/tendermint-0.1.0-optimized.jar
export CONTRACT_FILE_JAVA_XCALL_CONNECTION=$JAVASCORE_DIR/xcall-connection-0.1.0-optimized.jar
export CONTRACT_FILE_JAVA_XCALL=$JAVASCORE_DIR/xcall-0.1.0-optimized.jar
export CONTRACT_FILE_JAVA_XCALL_DAPP=$JAVASCORE_DIR/dapp-multi-protocol-0.1.0-optimized.jar

export CONTRACT_ADDR_JAVA_IBC_CORE=$ICON_ADDRESSES/.ibcCore
export CONTRACT_ADDR_JAVA_LIGHT_CLIENT=$ICON_ADDRESSES/.lightClient
export CONTRACT_ADDR_JAVA_XCALL_CONNECTION=$ICON_ADDRESSES/.xcallConnection
export CONTRACT_ADDR_JAVA_XCALL=$ICON_ADDRESSES/.xcall
export CONTRACT_ADDR_JAVA_XCALL_DAPP=$ICON_ADDRESSES/.xcallDapp

export GOVERNANCE_SCORE=cx0000000000000000000000000000000000000001


#################################################################################
####################  CREATE REQD DIRECTORY IF NOT EXISTS #######################
#################################################################################
mkdir -p $WASM_ADDRESSES
mkdir -p $ICON_ADDRESSES
