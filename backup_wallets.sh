#!/bin/bash

source const.sh
ts=$(date +"%Y-%m-%d_%H-%M-%S")
zipFile=$ts"_ibc_keystores".zip
zip -r $zipFile keystore > /dev/null
chmod -w $zipFile
cp $zipFile $HOME
