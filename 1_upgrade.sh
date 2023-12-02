#!/bin/bash

source icon.sh
source wasm.sh
source const.sh

: '
# Things under this upgrade
# 1. Update xcall contracts for icon, archway and neutron
'

echo "Fetching contracts"
WORK_DIR=$PWD

ICON_XCALL=$WORK_DIR/artifacts/xcall_0.2.0.jar
ICON_XCALL_CONNECTION=$WORK_DIR/artifacts/xcall-connection-0.1.0-optimized.jar 

WASM_XCALL=$WORK_DIR/artifacts/cw_xcall_0.2.0.wasm
WASM_IBC=$WORK_DIR/artifacts/cw_ibc_core_0.1.1.wasm
WASM_XCALL_CONNECTION=$WORK_DIR/artifacts/cw_xcall_ibc_connection_0.1.1.wasm

# Navigate to working directory
cd $WORK_DIR

# Fetch contracts to update
curl -L https://github.com/icon-project/IBC-Integration/releases/download/v1.1.0-hotfix/cw_ibc_core_0.1.1.wasm --output $WASM_IBC
curl -L https://github.com/icon-project/IBC-Integration/releases/download/v1.1.0-hotfix/cw_xcall_ibc_connection_0.1.1.wasm --output $WASM_XCALL_CONNECTION
curl -L https://github.com/icon-project/xcall-multi/releases/download/v1.1.0-hotfix/cw_xcall_latest.wasm --output $WASM_XCALL

curl -L https://github.com/icon-project/IBC-Integration/releases/download/v1.1.0-hotfix/xcall-connection-0.1.0-optimized.jar --output $ICON_XCALL_CONNECTION
curl -L https://github.com/icon-project/xcall-multi/releases/download/v1.1.0-hotfix/xcall-0.2.0-optimized.jar --output $ICON_XCALL

echo
echo

# update xcall on icon
if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"1_xcall_upgrade" ]; then
	update_contract xcall $ICON_XCALL networkId=0x1.icon 
	echo 1 > $LOGS/"$ICON_CHAIN_ID"_"1_xcall_upgrade"
fi

# update xcall connection on icon
if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"1_xcall_connection_upgrade" ]; then
	update_contract xcall-connection $ICON_XCALL_CONNECTION _xCall=cxa07f426062a1384bdd762afa6a87d123fbc81c75 _ibc=cx622bbab73698f37dbef53955fd3decffeb0b0c16 _port=xcall
	echo 1 > $LOGS/"$ICON_CHAIN_ID"_"1_xcall_connection_upgrade"
fi


# update xcall on archway
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_xcall_upgrade" ]; then
	migrate_contract xcall $WASM_XCALL '{"network_id":"archway-1"}'
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_xcall_upgrade"
fi

# update ibc core on archway
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_ibc_upgrade" ]; then
	migrate_contract ibc-core $WASM_IBC '{"clear_store": false}'
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_ibc_upgrade"
fi

# update connection-contract on archway
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_xcall_connection_upgrade" ]; then
	migrate_contract xcall-connection $WASM_XCALL_CONNECTION "{}"
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_xcall_connection_upgrade"
fi

# change cosmos network to neutron
sed -i 's/COSMOS=archway/COSMOS=neutron/' const.sh
source const.sh

# update xcall on neutron
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_xcall_upgrade" ]; then
	migrate_contract xcall $WASM_XCALL '{"network_id": "neutron-1"}'
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_xcall_upgrade"
fi

# update ibc core on neutron
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_ibc_upgrade" ]; then
	migrate_contract ibc-core $WASM_IBC '{"clear_store": false}'
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_ibc_upgrade"
fi

# update connection-contract on neutron
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_xcall_connection_upgrade" ]; then
	migrate_contract xcall-connection $WASM_XCALL_CONNECTION "{}"
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_xcall_connection_upgrade"
fi

# switch back to archway
sed -i 's/COSMOS=neutron/COSMOS=archway/' const.sh
source const.sh