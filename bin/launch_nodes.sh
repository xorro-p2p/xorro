#!/bin/bash

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launchnodes.sh port1 port2 port3 port4 ..."'
  echo
  echo "For each port number, a k-node will be launched with a Sinatra webserver running on that port"
  echo "The process will be backgrounded, and the PID written to pids.txt"
  echo
  echo "The first port number passed in will be the SuperNode, and all subsequent nodes will be made aware of it's port."
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

launch_nodes() {
  launch_super $1
  SUPERPORT=$1
  for port in ${@:2}
  do
    launch_node $port
  done
}

launch_super() {
  SUPER=true nohup ruby app.rb -p $1 >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_node() {
  SUPERPORT=$SUPERPORT nohup ruby app.rb -p $1 >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

if [[ $# == 0 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_nodes $@