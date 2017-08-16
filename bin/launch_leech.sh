#!/bin/bash
SUPERPORT=9999
SUPERIP=supernode1.xorro-p2p.com
IP=`dig +short myip.opendns.com @resolver1.opendns.com`

## takes one argument -- port to run leech node on.


help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launch_leech.sh port_number"'
  echo
  echo "This script is specifically for launching a client node that is behind a NAT/Firewall that:"
  echo "  A: does not want to contribute to network,"
  echo "  B: does not have any 3rd party tunnelling set up (Ngrok)"

}

if [[ $# -ne 1 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_leech() {
  PORT=$1 SUPERPORT=$SUPERPORT SUPERIP=$SUPERIP SUPER=false LEECH=true FQDN=$IP nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_leech $@