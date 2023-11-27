#!/bin/bash

source wasm.sh
source const.sh

: '
# Things under this upgrade
1. Upgrade wasm ibc contract
'

WORK_DIR=$PWD
WASM_IBC=$WORK_DIR/artifacts/cw_ibc_0.1.1.wasm

# Navigate to working directory
cd $WORK_DIR

# Fetch contracts to update
curl -L https://github.com/icon-project/IBC-Integration/releases/download/v1.0.0/cw_ibc_core_0.1.0.wasm --output $WASM_IBC

# update ibc-contract on archway
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"2_upgrade" ]; then
	migrate_contract ibc-core $WASM_IBC '{"clear_store": false}'
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"2_upgrade"
fi

# change cosmos network to neutron
sed -i 's/COSMOS=archway/COSMOS=neutron/' const.sh
source const.sh

# update xcall on neutron
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"2_upgrade" ]; then
	migrate_contract ibc-core $WASM_IBC '{"clear_store": false}'
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"2_upgrade"
fi

# switch back to archway
sed -i 's/COSMOS=neutron/COSMOS=archway/' const.sh
source const.sh
