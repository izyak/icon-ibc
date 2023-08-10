# Key and Fund Management


## Icon

It is comparatively easier to manage keys on icon. When you run the gochain docker container, it has a wallet called godWallet with address `hxb6b5791be0b5ef67063b3c10b840fb81514db2fd` and a large balance. 

It's keystore file is provided [here](https://github.com/izyak/gochain-btp/blob/master/data/godWallet.json). You can run the following command to get this and save it to `$HOME/keystore/godWallet.json`, which the script uses by default. The password for this wallet is `gochain`
```sh
mkdir -p $HOME/keystore && wget -O $HOME/keystore/godWallet.json https://raw.githubusercontent.com/izyak/gochain-btp/master/data/godWallet.json
```

### [Optional] Create wallet using goloop cli
```sh
goloop ks gen -o relayWallet.json -p 
```
To fund this wallet:
- For testnet:
    - Load funds from [here](https://faucet.iconosphere.io/). Ensure you load funds for the correct network from the dropdown.
- For gochain docker container
    - Run the following command
        ```sh
        goloop rpc sendtx transfer --to ${RELAY_WALLET_ADDR} --key_store ~/keystore/godWallet.json --key_password gochain --uri http://localhost:9082/api/v3/ --nid 3 --step_limit 1000000 --value 10000000000000000000000
        ```



## Cosmos 

This doc shows how you can create and manage keys for archway. This assumes you have `archwayd` and `rly` binaries. This will act as helper guide on setting up the wallets to deploy IBC contracts on archway and load funds to relayer wallet.

### Create wallet using archwayd
The following command creates a archway wallet named `godWallet` with keyring `os`
```sh
archwayd keys add godWallet
```
This wallet will not have any funds with it. To load fund to this wallet:
- For testnet
    - Load from the faucet channel of archway discord server
- For local docker container
    - The docker container already has a wallet called `fd` which has huge amount of tokens. We are going to transfer some tokens to out newly created `godWallet`. To transfer tokens, follow the following steps:
        - Go inside running archway docker container
            ```sh
            docker exec -it $ARCHWAY_CONTAINER_ID sh
            ```
        - It has a wallet called `fd` with keyring backend test. To view this wallet, run the following command.
            ```sh
            archwayd keys list --keyring-backend test
            ```
        - Check it's balance using the following command 
            ```sh
            archwayd query bank balances $FD_ADDRESS
            ```
        - Send fund to `godWallet` account created above.
            ```sh
            archwayd tx bank send fd $GODWALLET_ADDR 10000000stake --keyring-backend test  --chain-id localnet -y
            ```

This godWallet will be used to deploy all our contracts on this repository. You can use `fd` account if you want, but since it has keyring backend, you need to specify `WASM_EXTRA=" --keyring-backend test "` on consts.sh

### Create wallet using rly binary
The following command creates a wallet using the rly binary.
```sh
rly keys add archway relayWallet
```

To view the wallet you just created, run the following command.
```sh
rly keys show archway relayWallet
```

Load balance to this wallet as well in the same way as above based on testnet or local docker container.

This wallet will be saved to `.relayer/keys/${chain_id}/keyring-test/`. Hence, this keyPath on relay config on `cfg.sh`.

### One time Effort Way
It's a bit of a hacky way, but the easiest way to load balance however would be:
- On the archway repo, open `contrib/localnet/localnet.sh` file.
- Add te following lines:
    ```sh
    archwayd add-genesis-account $RELAY_WALLET_ADDR 100000000000000stake
    archwayd add-genesis-account $GOD_WALLET_ADDR 100000000000000stake
    ```
- Then, restart the archway docker container.
- You should always have enough balance for relayWllet and godWallet provided you follow this step.

