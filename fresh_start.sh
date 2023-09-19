#!/bin/bash

# Update package lists and install necessary packages
sudo apt-get update && \
sudo apt-get install -y curl sudo gcc git make bc jq vim wget

# Download and install Go 1.20
curl -O https://dl.google.com/go/go1.20.linux-amd64.tar.gz && \
tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz && \
rm go1.20.linux-amd64.tar.gz

# Add Go binary directory to the PATH environment variable
export PATH=$PATH:/usr/local/go/bin

# Create a directory for your Go projects in the home directory
mkdir -p ~/go/src ~/go/bin

# Set the GOPATH environment variable
export GOPATH=~/go
export PATH=$PATH:~/go/bin

# Set the home directory as the working directory
mkdir -p ~/workspace
cd ~/workspace

# Clone the archway repository and build goloop
go install github.com/icon-project/goloop/cmd/goloop@v1.3.8

git clone https://github.com/archway-network/archway  ~/workspace/archway && \
cd ~/workspace/archway && \
make install

git clone https://github.com/izyak/icon-ibc.git ~/workspace/icon-ibc