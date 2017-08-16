#!/bin/bash

DOMAIN=xorro-p2p.com
SUPERDNSNAME=supernode1.$DOMAIN
CLIENTPREFIX=client
SUPERPORT=9999

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "gcloud30.sh"'
  echo
  echo "This script is specifically for launching the xorro demo environment:  supernode on gcloud/aws server with 30 non-super nodes in same network."
  echo "DNS records for all nodes launched needs to be set up in advance"
  echo "DNS record and supernode IP/port will be hard coded into nodes @ip ivar."
  echo
}

if [[ $# -ne 0 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_gc_super() {
  #supernode broadcasts on superport, but has no separate superport that it checks in with
  PORT=$SUPERPORT SUPERPORT='' SUPER=true FQDN=$SUPERDNSNAME nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_gc_range() {
  ## iterate through range, creating non-super (client) node on port (9000 + range[p]), named 'client'  + $p + '.xorro-p2p.com'
  for p in $(seq $1 $2)
  do
    port=$(expr 9000 + $p)
    name=$CLIENTPREFIX$p.$DOMAIN
    launch_gc_client $port $name
    sleep 0.25
  done
}

launch_gc_client() {
  #client broadcasts on unique port, checks in with supernode on $SUPERPORT
  PORT=$1 SUPERPORT=$SUPERPORT SUPERIP=$SUPERDNSNAME SUPER=false FQDN=$2 nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_gc_super
sleep 3
launch_gc_range 1 30