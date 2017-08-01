#!/bin/bash

help_message() {
  echo 'duuuuuhhhhhhrrppppp'
}

if [[ $# -ne 1 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_public() {
  SUPERPORT='' SUPER=true WAN=true nohup ruby app.rb -p $1 >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_public $@