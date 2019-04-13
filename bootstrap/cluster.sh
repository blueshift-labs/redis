#! /bin/bash

masters=$REDIS_MASTERS
slaves=$REDIS_SLAVES
port=$REDIS_START_PORT

total_nodes=$((masters + masters * slaves))
echo "starting $total_nodes nodes: $masters master(s), $slaves slave(s) for each master..."

n=1
all_nodes=""

function start_node {
  echo "starting node $n at port: $port ..."
  all_nodes="$all_nodes 127.0.0.1:$port"
  cmd="redis-server --bind 0.0.0.0 --port $port --cluster-enabled yes --cluster-config-file nodes-$port.conf --protected-mode no --daemonize yes --dbfilename dump-$port.rdb --dir /var/redis --appendonly yes"
  echo "command: $cmd"
  eval $cmd
  port=$[$port + 1]
  n=$[$n + 1]
}

while [  $n -le $total_nodes ]; do
  start_node
  sleep 10
done

echo "creating cluster..."
cmd="printf 'yes\n'| redis-trib create --replicas $slaves $all_nodes"
echo "command: $cmd"
eval $cmd
