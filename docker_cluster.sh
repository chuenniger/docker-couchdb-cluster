#!/bin/sh

# docs: http://docs.couchdb.org/en/stable/setup/cluster.html#the-cluster-setup-api

# cleanup
echo 'Cleanup'
rm -Rf $(pwd)/couch1/ 
rm -Rf $(pwd)/couch2/ 
rm -Rf $(pwd)/couch3/

docker stop couch1.dc
docker stop couch2.dc
docker stop couch3.dc

docker rm couch1.dc
docker rm couch2.dc
docker rm couch3.dc

docker network rm couch

# create database directories
echo 'Create directories'
mkdir $(pwd)/couch1 $(pwd)/couch2 $(pwd)/couch3

# Create network
docker network create --driver bridge couch

# create docker container
echo 'Create container'
docker run -d --name couch1.dc --net=couch --hostname=couch1.dc -p  5984:5984 -e NODENAME=couch1.dc -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=admin -e ERL_FLAGS="-setcookie 'brumbrum'" -v $(pwd)/couch1:/opt/couchdb/data:Z couchdb:latest
docker run -d --name couch2.dc --net=couch --hostname=couch2.dc -p 15984:5984 -e NODENAME=couch2.dc -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=admin -e ERL_FLAGS="-setcookie 'brumbrum'" -v $(pwd)/couch2:/opt/couchdb/data:Z couchdb:latest
docker run -d --name couch3.dc --net=couch --hostname=couch3.dc -p 25984:5984 -e NODENAME=couch3.dc -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=admin -e ERL_FLAGS="-setcookie 'brumbrum'" -v $(pwd)/couch3:/opt/couchdb/data:Z couchdb:latest


# wait a minute
echo 'Wait 20 seconds'
sleep 20

# Setup Cluster
echo 'Setup cluster'
## Master
curl -X POST -H "Content-Type: application/json"  http://admin:admin@127.0.0.1:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address": "0.0.0.0", "username": "admin", "password": "admin", "node_count": "3"}'
curl -X POST -H "Content-Type: application/json" http://admin:admin@127.0.0.1:15984/_cluster_setup -d '{"action": "enable_cluster", "bind_address": "0.0.0.0", "username": "admin", "password": "admin", "node_count": "3"}'
curl -X POST -H "Content-Type: application/json" http://admin:admin@127.0.0.1:25984/_cluster_setup -d '{"action": "enable_cluster", "bind_address": "0.0.0.0", "username": "admin", "password": "admin", "node_count": "3"}'

## cluster 1
curl -X POST -H "Content-Type: application/json" http://admin:admin@127.0.0.1:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address": "0.0.0.0", "username": "admin", "password": "admin", "port": 5984, "node_count": "3", "remote_node": "couch2.dc", "remote_current_user": "admin", "remote_current_password": "admin"}'
curl -X POST -H "Content-Type: application/json" http://admin:admin@127.0.0.1:5984/_cluster_setup -d '{"action": "add_node", "host": "couch2.dc", "port": 5984, "username": "admin", "password": "admin"}'

## cluster 2
curl -X POST -H "Content-Type: application/json" http://admin:admin@127.0.0.1:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address": "0.0.0.0", "username": "admin", "password": "admin", "port": 5984, "node_count": "3", "remote_node": "couch3.dc", "remote_current_user": "admin", "remote_current_password": "admin"}'
curl -X POST -H "Content-Type: application/json" http://admin:admin@127.0.0.1:5984/_cluster_setup -d '{"action": "add_node", "host": "couch3.dc", "port": 5984, "username": "admin", "password": "admin"}'

## finish cluster
curl -X POST -H "Content-Type: application/json" http://admin:admin@127.0.0.1:5984/_cluster_setup -d '{"action": "finish_cluster"}'


echo 'Show setup'
curl http://admin:admin@127.0.0.1:5984/_cluster_setup
curl http://admin:admin@127.0.0.1:5984/_membership

echo 'Finished'

exit 0
