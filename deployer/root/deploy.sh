#!/bin/bash

show_help() {
    echo "Usage: "
    echo "  make [target]"
    echo "Available Targets:"
    echo "  artifact IBC_VERSION XCALL_VERSION      Download artifacts"
    echo "  icon-setup                              Setup ICON"
    echo "  wasm-setup                              Setup WASM"
    echo "  icon-cfg-ibc                            Configure IBC for ICON"
    echo "  wasm-cfg-ibc                            Configure IBC for WASM"
    echo "  icon-set-fee                            Set fee for ICON"
    echo "  wasm-set-fee                            Set fee for WASM"
    echo "  icon-set-protocol-fee                   Set protocol fee for ICON"
    echo "  wasm-set-protocol-fee                   Set protocol fee for WASM"
    echo "  icon-cfg-connection                     Configure connection for ICON"
    echo "  wasm-cfg-connection                     Configure connection for WASM"
    echo "  icon-default-connection                 Set default connection for ICON"
    echo "  wasm-default-connection                 Set default connection for WASM"
    echo "  config                                  Create Relay config file"
    echo "  icon-set-admin                          Set Admin for ICON"
    echo "  wasm-set-admin                          Set Admin for WASM"
    echo "Flags:"
    echo "  -h, --help                help for make"
}

# Check for the -h or --help option
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

option="$1"
arg1="$2"
arg2="$3"
cd /opt/deployer/root/icon-ibc

case "$option" in
  "artifact")
    echo "Downloading artifacts..."
    ./artifacts.sh $arg1 $arg2
    ;;
   "icon-setup")
    ./icon.sh --setup
    ;;
  "wasm-setup")
    ./wasm.sh --setup
    ;;
  "icon-cfg-ibc")
    ./icon.sh --configure-ibc
    ;;
  "wasm-cfg-ibc")
    ./wasm.sh --configure-ibc
    ;;
  "icon-set-fee")
    ./icon.sh --set-fee
    ;;
  "wasm-set-fee")
    ./wasm.sh --set-fee
    ;;
  "icon-set-protocol-fee")
    ./icon.sh --set-protocol-fee
    ;;
  "wasm-set-protocol-fee")
    ./wasm.sh --set-protocol-fee
    ;;
  "icon-cfg-connection")
    ./icon.sh -c $arg1 $arg2
    ;;
  "wasm-cfg-connection")
    ./wasm.sh -c $arg1 $arg2
    ;;
  "icon-set-admin")
	  ./icon.sh -a $arg1
    ;;
  "wasm-set-admin")
	  ./wasm.sh -a $arg1
    ;;
  "icon-default-connection")
    ./icon.sh -d
    ;;
  "wasm-default-connection")
    ./wasm.sh -d
    ;;
  *)
    echo "Invalid option"
    show_help
    exit 1
    ;;
esac


