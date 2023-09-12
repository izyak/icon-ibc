#!/bin/bash

source const.sh

function startNodeIcon() {
	cd $ICON_DOCKER_PATH
	make ibc-ready
}

function startNodeArchway() {
	cd $WASM_DOCKER_PATH
	docker compose up -d
}

function startNodeNeutron() {
	cd $WASM_DOCKER_PATH
	make start-docker-container
}

function stopNodeIcon() {
	cd $ICON_DOCKER_PATH
	make stop
}

function stopNodeArchway() {
	cd $WASM_DOCKER_PATH
	docker compose down
}

function stopNodeNeutron() {
	cd $WASM_DOCKER_PATH
	make stop-docker-container
}

function startBothNodes() {
	startNodeIcon
	startNodeArchway
}

function stopBothNodes() {
	stopNodeIcon
	stopNodeArchway
}

function usage() {
	echo "Script to run Icon and Wasm Nodes"
	echo 
	echo "Usage: "
	echo "         ./nodes.sh icon-node-start                : Start BTP enabled icon local node"
	echo "         ./nodes.sh archway-node-start             : Start archway local node"
	echo "         ./nodes.sh neutron-node-start             : Start neutron local node"
	echo "         ./nodes.sh icon-node-stop                 : Stop BTP enabled icon local node"
	echo "         ./nodes.sh archway-node-stop              : Stop archway local node"
	echo "         ./nodes.sh neutron-node-stop              : Stop neutron local node"
	echo "         ./nodes.sh start-all                      : Start icon and archway local nodes"
	echo "         ./nodes.sh close-all                      : Stop icon and archway local nodes"
}

if [ $# -eq 1 ]; then
	echo "Script to run Icon and Wasm Nodes"
    CMD=$1
fi

case "$CMD" in
  icon-node-start )
    startNodeIcon
  ;;
  archway-node-start )
    startNodeArchway
  ;;
  neutron-node-start )
    startNodeNeutron
  ;;
  icon-node-stop )
    startNodeIcon
  ;;
  archway-node-stop )
    startNodeArchway
  ;;
  neutron-node-stop )
    stopNodeNeutron
  ;;
  start-all )
    startBothNodes
  ;;
  close-all )
    stopBothNodes
  ;;
  * )
    echo "Error: unknown command: $CMD"
    usage
esac