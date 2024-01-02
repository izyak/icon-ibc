#!/bin/bash
KEYSTORE="/opt/deployer/root/keystore"
PASSWORD_FILE="/opt/deployer/root/keystore/secrets.json"
echo "Cleaning up old wallets ..."
yes | archwayd keys delete xcall_wallet --keyring-backend test >/dev/null 2>&1
yes | archwayd keys delete ibc_wallet --keyring-backend test >/dev/null 2>&1
echo "Fetching wallets ..."
python3 /opt/deployer/root/keyutils/decrypt.py >/dev/null 2>&1
# Check wallet load
echo "Checking ICON ibc wallet ..."
goloop ks verify ${KEYSTORE}/ibc_wallet.json -p $(grep 'icon_ibc_wallet_secret' $PASSWORD_FILE | awk -F\" '{print $4}') 2>/dev/null || echo FAILED
echo "Checking ICON xcall wallet ..."
goloop ks verify ${KEYSTORE}/xcall_wallet.json -p $(grep 'icon_xcall_wallet_secret' $PASSWORD_FILE | awk -F\" '{print $4}') 2>/dev/null || echo FAILED
echo "Checking Archway ibc wallet ..."
archwayd keys list --keyring-backend test | grep -q ibc_wallet && echo SUCCESS || echo FAILED
echo "Checking Archway xcall wallet ..."
archwayd keys list --keyring-backend test | grep -q xcall_wallet && echo SUCCESS || echo FAILED
echo "Checking Injective ibc wallet ..."
injectived keys list --keyring-backend test | grep -q ibc_wallet && echo SUCCESS || echo FAILED
echo "Checking Injective xcall wallet ..."
injectived keys list --keyring-backend test | grep -q xcall_wallet && echo SUCCESS || echo FAILED
## Check injectived keys id
injectived keys list --keyring-backend test | grep -E 'address|name'
echo "Checking Neutron ibc wallet ..."
neutrond keys list --keyring-backend test | grep -q ibc_wallet && echo SUCCESS || echo FAILED
echo "Checking Neutron xcall wallet ..."
neutrond keys list --keyring-backend test | grep -q xcall_wallet && echo SUCCESS || echo FAILED
## Check Neutron keys id
neutrond keys list --keyring-backend test | grep -E 'address|name'
# Remove permission for all the other users
chmod 700 /opt/deployer/root/keystore/*
