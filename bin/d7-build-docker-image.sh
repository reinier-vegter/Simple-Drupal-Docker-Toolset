#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

## PHP 54
dockerfile_folder="${mydir}/../dockerfiles/d7/php54"
docker build -t fin-d7-54 ${dockerfile_folder}

## PHP 5.6
dockerfile_folder="${mydir}/../dockerfiles/d7/php56"
docker build -t fin-d7-56 ${dockerfile_folder}

# PHP 7.0
dockerfile_folder="${mydir}/../dockerfiles/d7/php70"
docker build -t fin-d7-70 ${dockerfile_folder}
