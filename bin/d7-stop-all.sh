#!/bin/bash

echo "This will stop and remove all d7 containers"
echo "Proceed ? Press ctr-c to abort, or enter to proceed"
read input

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

for container in $(docker ps -a --filter "name=dev-" --format "{{.ID}}"); do
  docker stop -t 1 "$container"
  docker rm "$container"
done
echo "Done"
