#!/usr/bin/env bash

set -e

# add to your ~/.tmux.conf:
# set-window-option -g mouse on
# set -g default-terminal "tmux-256color"

# start a tmux session:
# tmux new-session -s 'Demo' -t demo

# then run this script
RUNNER=${RUNNER:-cabal new-run -v0 --}

genesis="33873"
genesis_root="configuration/${genesis}"
genesis_file="${genesis_root}/genesis.json"
if test ! -f "${genesis_file}"
then echo "ERROR: genesis ${genesis_file} does not exist!">&1; exit 1; fi

genesis_hash="$(${RUNNER} cardano-cli --log-config configuration/log-configuration.yaml --real-pbft print-genesis-hash --genesis-json ${genesis_file})"

ALGO="--real-pbft"
# SCR="./scripts/start-node.sh"
# CMD="stack exec --nix cardano-node --"
CMD="cabal new-run exe:cardano-node --"

# SPECIAL=""
SPECIAL="--live-view"
# VERBOSITY="--tracing-verbosity-minimal"
# VERBOSITY="--tracing-verbosity-normal"
VERBOSITY="--tracing-verbosity-maximal"
HOST="127.0.0.1"
HOST6="::1"

function mklogcfg () {
  echo "--log-config configuration/log-config-${1}.yaml"
}
function mkdlgkey () {
  printf -- "--signing-key            ${genesis_root}/delegate-keys.%03d.key" "$1"
}
function mkdlgcert () {
  printf -- "--delegation-certificate ${genesis_root}/delegation-cert.%03d.json" "$1"
}

function mknetargs () {
               printf -- "--slot-duration 2 "
               printf -- "--genesis-file ${genesis_file} "
               printf -- "--genesis-hash ${genesis_hash} "
               printf -- "--pbft-signature-threshold 0.7 "
               printf -- "--require-network-magic "
               printf -- "--database-path db "
               printf -- "node "
               printf -- "--topology configuration/simple-topology.json "
               printf -- "--trace-block-fetch-decisions "
               printf -- "--trace-block-fetch-client "
               printf -- "--trace-block-fetch-server "
               printf -- "--trace-tx-inbound "
               printf -- "--trace-tx-outbound "
               printf -- "--trace-local-tx-submission-server "
               printf -- "--trace-mempool "
               printf -- "--trace-forge "
               printf -- "--trace-chain-sync-protocol "
               printf -- "--trace-block-fetch-protocol "
               printf -- "--trace-tx-submission-protocol "
               printf -- "--trace-local-chain-sync-protocol "
               printf -- "--trace-local-tx-submission-protocol "
               printf -- "${ALGO}"
}

# for acceptor logs:
mkdir -p logs/

PWD=$(pwd)

tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v

tmux select-pane -t 0
tmux send-keys "cd '${PWD}'; ${CMD} $(mklogcfg 0) $(mkdlgkey 0) $(mkdlgcert 0) $(mknetargs) -n 0 --host-addr ${HOST6} --port 3000 ${VERBOSITY}" C-m
tmux select-pane -t 1
tmux send-keys "cd '${PWD}'; ${CMD} $(mklogcfg 1) $(mkdlgkey 1) $(mkdlgcert 1) $(mknetargs) -n 1 --host-addr ${HOST}  --port 3001 ${VERBOSITY}" C-m
tmux select-pane -t 2
tmux send-keys "cd '${PWD}'; ${CMD} $(mklogcfg 2) $(mkdlgkey 2) $(mkdlgcert 2) $(mknetargs) -n 2 --host-addr ${HOST6} --port 3002 ${VERBOSITY}" C-m
