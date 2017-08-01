#!/bin/bash

while read p
  do 
    kill -9 $p 
  done<tmp/pids.txt

killall ngrok 2>/dev/null

> tmp/pids.txt

