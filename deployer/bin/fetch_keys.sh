#!/bin/bash
echo "Cleaning up old wallets ..."
yes | archwayd keys delete xcall_wallet --keyring-backend test >/dev/null 2>&1
yes | archwayd keys delete ibc_wallet --keyring-backend test >/dev/null 2>&1
echo "Fetching wallets ..."
python3 /opt/deployer/root/keyutils/decrypt.py >/dev/null 2>&1
# Check wallet load
if [ "$(archwayd keys list --keyring-backend test | wc -l)" == "2" ];then
	echo "Error: Wallet didnot loaded"
	exit 1
fi
echo "Successfully loaded Wallets !"