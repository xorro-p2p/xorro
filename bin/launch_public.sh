#!/bin/bash

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launch_public.sh local_port_number"'
  echo
  echo "This script does the following:"
  echo "--Launches local node/sinatra instance on port number passed in."
  echo "Creates ngrok tunnel to localhost."
  echo "Starts communications with default supernode in AWS cloud on port 3500."
  echo
  echo "Node can be killed by running bin/kill_nodes.sh"
}

if [[ $# -ne 1 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_public() {
  SUPERPORT='3500' SUPERIP='supernode1.xorro-p2p.com' WAN=true nohup ruby app.rb -p $1 >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_public $@