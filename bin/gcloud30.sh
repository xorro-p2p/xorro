#!/bin/bash

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "gcloud30.sh"'
  echo
  echo "This script is specifically for launching the xorro demo environment:  supernode on gcloud/aws server with 30 non-super nodes in same network."
  echo "DNS record and supernode IP/port will be hard coded into nodes @ip ivar."
}

if [[ $# -ne 0 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_gc_super() {
  PORT=9999 SUPERPORT='' SUPER=true FQDN=supernode1.xorro-p2p.com nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_gc_client() {
  PORT=$1 SUPERPORT='9999' SUPERIP='supernode1.xorro-p2p.com' SUPER=false FQDN=$2 nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_gc_range() {
  for p in $(seq $1 $2)
  do
    port=$(expr 9000 + $p)
    name=client$p.xorro-p2p.com
    launch_gc_client $port $name
    sleep 0.25
  done
}

launch_node() {
  PORT=$1 SUPERPORT=$SUPERPORT SUPER=false nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_gc_super
sleep 3
launch_gc_range 1 30