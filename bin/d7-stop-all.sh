#!/bin/bash

echo "This will stop and remove all d7 containers"
echo "Proceed ? Press ctr-c to abort, or enter to proceed"
read input

for container in $(docker ps -a --filter "name=d7." --format "{{.ID}}"); do
  docker stop -t 1 "$container"
  docker rm "$container"
done
echo "Done"
