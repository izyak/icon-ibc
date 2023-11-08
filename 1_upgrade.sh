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
WASM_XCALL=$WORK_DIR/artifacts/cw_xcall_0.2.0.wasm

# Navigate to working directory
cd $WORK_DIR

# Fetch contracts to update
curl -L https://github.com/icon-project/xcall-multi/releases/download/v1.0.0/cw_xcall_0.2.0.wasm --output $WASM_XCALL
curl -L https://github.com/icon-project/xcall-multi/releases/download/v1.0.0/xcall-0.2.0-optimized.jar --output $ICON_XCALL
echo
echo

# update xcall on icon
if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"1_upgrade" ]; then
	update_contract xcall $ICON_XCALL networkId=0x3.icon
	echo 1 > $LOGS/"$ICON_CHAIN_ID"_"1_upgrade"
fi

# update xcall on archway
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_upgrade" ]; then
	migrate_contract xcall $WASM_XCALL "{}"
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_upgrade"
fi

# change cosmos network to neutron
sed -i 's/COSMOS=archway/COSMOS=neutron/' const.sh
source const.sh

# update xcall on neutron
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"1_upgrade" ]; then
	migrate_contract xcall $WASM_XCALL "{}"
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"1_upgrade"
fi

# switch back to archway
sed -i 's/COSMOS=neutron/COSMOS=archway/' const.sh
source const.sh