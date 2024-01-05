#!/bin/bash

source wasm.sh
source const.sh

: '
# Things under this upgrade
# 1. Instantiate xcall on injective with correct parameters
  2. Change the xcall host on wasm xcall-connection
  3. Set default connection on new xcall
'

prev_xcall_addr=(cat $CONTRACT_ADDR_WASM_XCALL)

if [[ "$prev_xcall_addr" -ne "inj1sc8jqug4pz7uytlnya5s3zq22p93wth2glw8e4" ]]; then
    echo "Incorrect xcall"
    exit 0
fi

echo "Proceeding with instantiating new xcall..."
# rm $CONTRACT_ADDR_WASM_XCALL
rm /opt/deployer/root/icon-ibc/ixc/injective-1_set_xcall_host_1
rm /opt/deployer/root/icon-ibc/ixc/injective-1_set_xcall_host
# rm /opt/deployer/root/icon-ibc/ixc/injective-1_set_default_connection

# instantiate new xcall
# if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"xcall_instantiate_2" ]; then
# 	xcall_args="{\"network_id\":\"injective-1\",\"denom\":\"inj\"}"
# 	deploy_contract $CONTRACT_FILE_WASM_XCALL $CONTRACT_ADDR_WASM_XCALL ${xcall_args} "$WASM_XCALL_COMMON_ARGS" $WASM_XCALL_WALLET "${INJ_CODE_ID[cw_xcall]}"
# 	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"xcall_instantiate_2"
# fi

# set xcall host on xcall-connection
if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"set_xcall_host_1" ]; then
	set_xcall_host
	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"set_xcall_host_1"
fi

# delete prev log that prevents setting default connection
# rm $LOGS/"$WASM_CHAIN_ID"_"set_default_connection"

# # set default connection for icon
# if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"set_default_connection_1" ]; then
# 	set_default_connection
# 	echo 1 > $LOGS/"$WASM_CHAIN_ID"_"set_default_connection_1"
# fi

