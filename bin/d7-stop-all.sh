#!/bin/bash

echo "This will stop and remove all php, mysql and solr containers"
echo "Proceed ? Press ctr-c to abort, or enter to proceed"
read input

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

echo "Stopping php containers"
for container in $(docker ps -a --filter "name=d7." --format "{{.ID}}"); do
  docker stop -t 1 "$container"
  docker rm "$container"
done

echo ""
echo "Stopping mysql container"
d7-mysql-stop

echo ""
echo "Stopping solr container"
d7-solr-stop

if [ ${OSX} -eq 1 ]; then
  echo ""
  echo "Stopping proxy"
  d7-proxy-stop
fi
