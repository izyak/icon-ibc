
.PHONY: clean
clean:
	rm -Rf env

nodes:
	./nodes.sh start-all

stop-nodes:
	./nodes.sh close-all

restart:
	./nodes.sh close-all
	./nodes.sh start-all

contracts:
	./icon.sh --setup
	./wasm.sh --setup
	./icon.sh --deploy-dapp
	./wasm.sh --deploy-dapp
	./cfg.sh

config:
	./cfg.sh

handshake:
	rly tx clients icon-archway --client-tp "10000000m"
	rly tx conn icon-archway
	./icon.sh -c
	./wasm.sh -c
	rly tx chan icon-archway --src-port=xcall --dst-port=xcall