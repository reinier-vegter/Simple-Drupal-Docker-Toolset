#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

name='docker.mysql'
docker stop ${name}
docker rm ${name}

container_hostname='mysql-docker.dev'
"${mydir}"/d7-hosts-entry.sh remove ${container_hostname}
