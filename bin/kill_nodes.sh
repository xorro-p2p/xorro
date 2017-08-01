#!/bin/bash

while read p
  do 
    kill -9 $p 
  done<tmp/pids.txt

killall ngrok

> tmp/pids.txt

