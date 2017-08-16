#!/bin/bash

## launches single supernode on local machine, 
## take 1 argument:  port that sinatra web app will run on.
## no nat translation or communications with network are assumed

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launch_super.sh port_number"'
  echo
  echo "Only one port number is accepted. A supernode will be launched with a Sinatra webserver running on that port"
  echo "The process will be backgrounded, and the PID written to pids.txt"
  echo
  echo "You can a range of launch client nodes using launch_range, passing in the supernode port, client starting port, and client ending port."
  echo
  echo "You can quit the processes in bulk using kill_nodes.sh, which iterates through pids.txt,"
  echo "kills each process, then overwrites the file"
  echo
  echo "Alternatively you can locate each pid using" 
  echo "lsof -i \$port_number" 
  echo "and kill it manually:"
  echo "kill \$pid"
  echo "however this could result in inconsistencies with your pids.txt file."
  echo
}

if [[ $# -ne 1 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_local_super() {
  PORT=$1 SUPERPORT='' SUPER=true nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_local_super $@