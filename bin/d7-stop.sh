#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

docker stop -t 1 ${d7_container_name}
docker rm ${d7_container_name}
echo "Container '$d7_container_name' stopped and removed".

# Stop solr container.
d7-solr4-stop
