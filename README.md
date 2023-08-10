## ICON-IBC-SETUP

This repository contains scripts to
- start ICON, COSMOS chain nodes
- deploy and configure all the contracts required for ICON-IBC integration between ICON and COSMOS chain. 
	- ibc
	- light client 
	- xcall 
	- xcall-connection
	- xcall-dapp
- deploy and configure xcall to be used with IBC
- relay packets using IBC and xcall

## Prerequisities
- ### jq
Install jq
```sh
sudo apt install jq
brew install jq
sudo pacman -S jq
```

- ### yq
Install yq
```sh
go install github.com/mikefarah/yq/v4@latest
```


- ### gochain-btp
This is a modded repo which makes it easier to open btp network. Clone this repo on your home directory
```sh
git clone https://github.com/izyak/gochain-btp
```

- ### archway / neutron docker 
	Read build guide for respective chains from this repo.
	- [archwayd](https://github.com/archway-network/archway)
	- [neutrond](https://github.com/neutron-org/neutron)

- ### goloop
```sh
go install github.com/icon-project/goloop/cmd/goloop@latest
```

- ### [ Wasm ] Daemon

	One among these. Follow the link for respective chain to get respective daemon.
	- [archwayd](https://github.com/archway-network/archway)
	- [neutrond](https://github.com/neutron-org/neutron)

- ### IBC-Integration
Clone the repo and build contracts
```sh
git clone --recurse-submodules https://github.com/icon-project/IBC-Integration
cd IBC-Integration
make build-builder-img
make optimize-build
```
- ### IBC-Relay
Clone the repo and build relay binary
```sh
git clone https://github.com/icon-project/ibc-relay
cd ibc-relay
make install
```

After you run `make install` command, you can now use `rly` binary to interact with the relay



## Notes
- The files `nodes.sh` contains guide to start and stop icon and archway images. 
- This script deploys a mock-dapp on the IBC-Integrations repo. This can be replaced with your dapp as well.


## Usage
Update `const.sh` as per your requirement. Ideally, you should be okay with changing the fields under `CHANGE` header. 

If you are not sure on how to load wallets required for deploying and running the relay and get funds on them, read [this](./docs/keys.md) guide.

By default, this script uses archway node. The respective command to run neutron nodes is in `nodes.sh` file. Instead of running `make nodes`, you can run neutron and icon chains seaparately using `nodes.sh` script.

Change the location of IBC-Integrations, gochain-btp, archway node repo. By default, they'll be in the home directory in the script. Then, follow the steps as follows:

#### Chain Setup
- To start nodes of icon and archway
	```sh
	make nodes
	```

#### Contract Deployment
- The following command deploys and configures contract for both ICON and wasm chains. Similarly, it generates a config file for relay to run. Make sure the node is up
	```sh
	make contracts
	```

#### Setup IBC
- This command does the following things
	- create client for both chains
	- establish connection between the chains
	- configure connnection on contracts [xcall specific thing]
	- establish channel between the chains

	```sh
	make handshake
	```

#### Start Relay
- Start relay with the following command
	```sh
	rly start
	```

#### Send Packets
- On another terminal, run the following command
	- Send packet from Icon chain
		```sh
		./icon.sh -m

		```

	- Send packet from Cosmos Chain

		```sh
		./wasm.sh -m

		```