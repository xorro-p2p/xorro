#!/bin/bash
SUPERPORT=9999
SUPERIP=supernode1.xorro-p2p.com

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launch_pf_public.sh port_number FQDN"'
  echo
  echo "This script is specifically for launching a public facing client node in an environment where either"
  echo "A:  system is directly on the public internet with a publicly accessible IP address"  
  echo "B:  system is behind a nat/firewall, but port forwarding is properly configured for the port_number passed in as the first argument"
}

if [[ $# -ne 2 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_pf_public() {
  PORT=$1 SUPERPORT=$SUPERPORT SUPERIP=$SUPERIP SUPER=false FQDN=$2 nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_pf_public $@