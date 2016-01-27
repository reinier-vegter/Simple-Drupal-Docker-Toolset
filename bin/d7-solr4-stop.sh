#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

docker stop -t 1 ${solr_container_name}
docker rm ${solr_container_name}
echo "Container '$solr_container_name' stopped and removed".
