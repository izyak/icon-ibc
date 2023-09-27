
.PHONY: clean
clean:
	rm -Rf env
	rm -Rf ixc

start:
	./fresh_start.sh

artifact:
	./artifacts.sh ${ibc-version} ${xcall-version}

wallets:
	./icon.sh --wallets
	./wasm.sh --wallets
	echo "Load funds to generated wallets"

icon-setup:
	./icon.sh --setup

wasm-setup:
	./wasm.sh --setup

icon-cfg-ibc:
	./icon.sh --configure-ibc

wasm-cfg-ibc:
	./wasm.sh --configure-ibc

icon-set-fee:
	./icon.sh --set-fee

wasm-set-fee:
	./wasm.sh --set-fee

icon-set-protocol-fee:
	./icon.sh --set-protocol-fee

wasm-set-protocol-fee:
	./wasm.sh --set-protocol-fee

icon-cfg-connection:
	./icon.sh -c ${client_id} ${conn_id}

wasm-cfg-connection:
	./wasm.sh -c ${client_id} ${conn_id}

icon-set-admin:
	./icon.sh -a ${admin}

wasm-set-admin:
	./wasm.sh -a ${admin}
	
icon-default-connection:
	./icon.sh -d

wasm-default-connection:
	./wasm.sh -d

contracts:
	./icon.sh --setup
	./wasm.sh --setup
	./icon.sh --configure-ibc
	./wasm.sh --configure-ibc
	./icon.sh --set-fee
	./wasm.sh --set-fee
	./icon.sh --set-protocol-fee
	./wasm.sh --set-protocol-fee
	./cfg.sh

config:
	./cfg.sh

configure-connection:
	./icon.sh -c
	./wasm.sh -c
	./icon.sh -d
	./wasm.sh -d

migrate:
	./migrate.sh migrate ${wasm-file} ${contract-addr} ${migrate-args}

handshake:
	echo "Get the BTP Height to initialize light client with, then replace the btp block height and uncomment the following lines"
# 	rly tx clients icon-archway --client-tp "10000000m" --btp-block-height 13257698
# 	rly tx conn icon-archway
# 	./icon.sh -c
# 	./wasm.sh -c
# 	./icon.sh -d
# 	./wasm.sh -d
# 	rly tx chan icon-archway --src-port=xcall --dst-port=xcall