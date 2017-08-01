#!/bin/bash

help_message() {
  echo 'duuuuuhhhhhhrrppppp'
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