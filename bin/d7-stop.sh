#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

docker stop -t 1 ${d7_container_name}
docker rm ${d7_container_name}

# Generate hostname.
# TODO: this should only be ran if container really does exist.
# Otherwise, if this is done in a folder called 'local' of 'com', a lot
# of entries will be removed.
# container_hostname="dev.$(basename `pwd`).local"
# "${mydir}"/d7-hosts-entry.sh remove ${container_hostname}

echo "Container '$d7_container_name' stopped and removed".

# Stop solr container.
d7-solr4-stop
