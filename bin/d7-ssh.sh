#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

 [ "$1" != "" ] && d7_container_name=$1
docker exec -i -t ${d7_container_name} bash
