#!/bin/bash

help_message() {
  echo
  echo 'looks like you need some help using this tool.'
  echo
  echo 'usage:  "launch_aws.sh port_number"'
  echo
  echo "This script is specifically for launching the AWS supernode.  AWS public DNS record will be hard coded into nodes @ip ivar."
}

if [[ $# -ne 0 ]] || [[ $1 == '-h' ]]; then
  help_message
  exit 0
fi

launch_aws_super() {
  PORT=9999 SUPERPORT='' SUPER=true AWS=true nohup ruby app.rb >> tmp/nohup.out &
  echo $! >> tmp/pids.txt
}

launch_aws_super