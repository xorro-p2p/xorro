#!/bin/bash

while read p
  do 
    kill $p 
  done<tmp/pids.txt

> tmp/pids.txt
