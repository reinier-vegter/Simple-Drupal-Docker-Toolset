#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

cmd="cd /var/www; drush $@"
docker exec -i -u www-data -t ${d7_container_name} bash -c "$cmd"
