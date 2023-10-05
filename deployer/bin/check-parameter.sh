#!/bin/bash
echo
echo "#######  Check Loaded Env Parameters ########"
echo
echo
cd /opt/deployer/root/icon-ibc
source ./const.sh
for var in $(cat const.sh | grep export | grep -v 'PASSWORD' | awk '{print $2}' | awk -F\= '{print $1}');do
	env | grep "$var"
done