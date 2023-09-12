
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
	./cfg.sh

config:
	./cfg.sh

handshake:
	echo "Get the BTP Height to initialize light client with, then replace the btp block height and uncomment the following lines"
# 	rly tx clients icon-archway --client-tp "10000000m" --btp-block-height 13257698
# 	rly tx conn icon-archway
# 	./icon.sh -c
# 	./wasm.sh -c
# 	rly tx chan icon-archway --src-port=xcall --dst-port=xcall
# 	rly tx chan icon-archway --src-port=0x7.icon-mock-module --dst-port=0x3.wasm-mock-module -o ordered