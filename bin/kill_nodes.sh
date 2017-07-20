#!/bin/bash

while read p
  do 
    kill $p 
  done<pids.txt

> pids.txt
