#!/bin/bash

source icon.sh
source const.sh

: '
# Things under this upgrade
# 1. Update light-client contracts for icon
'

echo "Fetching contracts"
WORK_DIR=$PWD
ICON_LIGHT_CLIENT=$WORK_DIR/artifacts/tendermint-0.1.0-optimized.jar
ibc_handler=$(cat $CONTRACT_ADDR_JAVA_IBC_CORE)

# Navigate to working directory
cd $WORK_DIR
shasum $ICON_LIGHT_CLIENT
# Fetch contracts to update
# curl -L https://github.com/icon-project/IBC-Integration/releases/download/v1.0.0/tendermint-0.1.0-optimized.jar --output $ICON_LIGHT_CLIENT
echo
echo
echo $ibc_handler
# update light_client on icon
if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"1_upgrade" ]; then
	update_contract light-client $ICON_LIGHT_CLIENT ibcHandler=$ibc_handler
	echo 1 > $LOGS/"$ICON_CHAIN_ID"_"1_upgrade"
fi
