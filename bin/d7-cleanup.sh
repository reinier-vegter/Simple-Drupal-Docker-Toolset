#!/bin/bash

echo "This will remove (disposable) stoppped containers, where the name contains 'd7.'"
echo "Proceed ? Press ctr-c to abort, or enter to proceed"
read input

for container in $(docker ps -a --filter "name=d7." --filter "status=exited" --format "{{.ID}}"); do
  docker rm "$container"
done

echo "Done"
