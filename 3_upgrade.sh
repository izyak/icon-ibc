#!/bin/bash

source icon.sh
source const.sh

: '
# Things under this upgrade
# 1. Update tendermint light client contracts on icon for neutron
'

echo "Fetching contracts"
WORK_DIR=$PWD





# Fetch contracts to update

echo


ICON_XCALL_CONNECTION=$WORK_DIR/artifacts/xcall-connection-0.1.2-optimized.jar

# Navigate to working directory
cd $WORK_DIR


curl -L https://github.com/icon-project/IBC-Integration/releases/download/v1.1.2/xcall-connection-0.1.2-optimized.jar --output $ICON_XCALL_CONNECTION
echo 
if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"1.2_xcall_connection_upgrade" ]; then
    update_contract xcall-connection $ICON_XCALL_CONNECTION _xCall=cxa07f426062a1384bdd762afa6a87d123fbc81c75  _ibc=cx622bbab73698f37dbef53955fd3decffeb0b0c16  _port=xcall
    echo 1 > $LOGS/"$ICON_CHAIN_ID"_"1.2_xcall_connection_upgrade"
fi