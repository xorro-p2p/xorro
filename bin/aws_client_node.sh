#!/bin/bash

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "aws_client_node.sh port_number FQDN"'
  echo
  echo "This script is specifically for launching a client node on AWS.  AWS public DNS record and supernode IP/port will be hard coded into nodes @ip ivar."
}

if [[ $# -ne 2 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_aws_client() {
  PORT=$1 SUPERPORT='9999' SUPERIP='supernode1.xorro-p2p.com' SUPER=false FQDN=$2 nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_aws_client $@