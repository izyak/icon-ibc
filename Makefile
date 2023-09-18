
.PHONY: clean
clean:
	rm -Rf env
	rm -Rf ixc

wallets:
	./icon.sh --wallets
	./wasm.sh --wallets
	./backup_wallets.sh
	echo "Load funds to generated wallets"

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

handshake:
	echo "Get the BTP Height to initialize light client with, then replace the btp block height and uncomment the following lines"
# 	rly tx clients icon-archway --client-tp "10000000m" --btp-block-height 13257698
# 	rly tx conn icon-archway
# 	./icon.sh -c
# 	./wasm.sh -c
# 	./icon.sh -d
# 	./wasm.sh -d
# 	rly tx chan icon-archway --src-port=xcall --dst-port=xcall