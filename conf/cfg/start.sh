#!/bin/bash

NODES=6
BASEPORT=8700
for ((i<0; i<$NODES;i++))
do
  PORT=$((BASEPORT+i))
  echo $PORT
  redis-server /etc/redis/cluster/cfg/$PORT.conf &
done
