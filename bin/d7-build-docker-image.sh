#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

### PHP 54
#dockerfile_folder="${mydir}/../dockerfiles/d7/php54"
#image="rvegter/simple-drupal-docker-toolset:php54"
#docker rmi -f ${image}
#docker build -t ${image} ${dockerfile_folder}

## PHP 5.6
dockerfile_folder="${mydir}/../dockerfiles/d7/php56"
image="rvegter/simple-drupal-docker-toolset:php56"
docker rmi -f ${image}
docker build -t ${image} ${dockerfile_folder}

## PHP 7.0
#dockerfile_folder="${mydir}/../dockerfiles/d7/php70"
#image="rvegter/simple-drupal-docker-toolset:php70"
#docker rmi -f ${image}
#docker build -t ${image} ${dockerfile_folder}
