#!/bin/bash

source icon.sh
source const.sh

: '
# Things under this upgrade
# 1. Update tendermint light client contracts on icon for neutron
'

echo "Fetching contracts"
WORK_DIR=$PWD

ICON_TM_CLIENT=$WORK_DIR/artifacts/xcall-connection-0.1.2-optimized.jar


# Navigate to working directory
cd $WORK_DIR

# Fetch contracts to update
curl -L https://github.com/icon-project/IBC-Integration/releases/download/v1.1.2/xcall-connection-0.1.2-optimized.jar --output $ICON_TM_CLIENT

echo

# update xcall on icon
if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"1_tm_client_upgrade" ]; then
	update_contract light-client $ICON_TM_CLIENT ibcHandler=cx622bbab73698f37dbef53955fd3decffeb0b0c16 update=0x1
	echo 1 > $LOGS/"$ICON_CHAIN_ID"_"1_tm_client_upgrade"
fi