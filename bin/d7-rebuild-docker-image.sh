#!/bin/bash

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)
dockerfile_folder="${mydir}/../dockerfiles/d7"
docker build --rm=true -t finalist-drupal7 ${dockerfile_folder}
