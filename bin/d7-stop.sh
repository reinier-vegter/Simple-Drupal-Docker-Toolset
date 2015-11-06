#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

image='finalist-drupal7'

# generate hostname.
container_hostname="dev-$(basename `pwd`)-local"
name=$container_hostname

docker stop -t 1 ${name}
docker rm ${name}
echo "Container '$name' stopped and removed".
