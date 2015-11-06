#!/bin/bash

if [ "$1" != "" ]; then
  tail=$1
else
  tail=100
fi

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

container_hostname="dev-$(basename `pwd`)-local"
name=$container_hostname
docker logs --tail=$tail -f ${name}
