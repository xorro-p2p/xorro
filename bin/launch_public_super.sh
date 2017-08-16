#!/bin/bash
PORT=9999
FQDN=supernode1.xorro-p2p.com

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launch_public_super.sh port_number"'
  echo
  echo "This script is specifically for launching the supernode in an environment where:"
  echo  "1: DNS name already exists for this supernode - configure it as the FQDN variable in the script"
  echo  "2: Supernode is either directly on the internet, or port forwarding/NAT is properly set up for the PORT variable"
  echo 
}

if [[ $# -ne 0 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_public_super() {
  PORT=$PORT SUPERPORT='' SUPER=true FQDN=$FQDN nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_aws_super