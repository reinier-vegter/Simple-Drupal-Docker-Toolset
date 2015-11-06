#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

dockerfile_folder="${mydir}/../dockerfiles/d7"
docker build --rm=true -t finalist-drupal7 ${dockerfile_folder}
