#!/bin/bash

echo "This will remove (disposable) stopped containers, where the name contains 'd7.'"
echo "Proceed ? Press ctr-c to abort, or enter to proceed"
read input

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

for container in $(docker ps -a --filter "name=d7." --filter "status=exited" --format "{{.ID}}"); do
  docker rm "$container"
done

echo "Done"
