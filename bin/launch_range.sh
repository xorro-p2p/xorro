help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launch_range.sh super_node_port_number starting_port_number ending_port_number"'
  echo
  echo "Script takes 3 arguments"
  echo
  echo "The first argument is the port of an ALREADY RUNNING super_node"
  echo
  echo "The second and third arguments are starting and ending port numbers"
  echo "The starting port must be lower than the ending port, and have no overlap with the supernode port"
  echo
  echo "Client node will be launched on each node within that range inclusive"
  echo "Each client will begin communicating with the supernode passed in as the first argument"
  echo "The processes will be backgrounded, and the PID written to pids.txt"

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

launch_range() {
  SUPERPORT=$1
  for port in $(seq $2 $3)
  do
    launch_node $port
  done
}

launch_node() {
  SUPERPORT=$SUPERPORT SUPER=false nohup ruby app.rb -p $1 >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}


if [[ $# -ne 3 ]] || [[ $1 == '-h' ]] || [[ $2 -gt $3 ]]; then
  help_message
  exit 0
fi


launch_range $@