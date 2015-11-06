#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

name='docker.open-proxy'
docker stop -t 1 ${name}
docker rm ${name}
