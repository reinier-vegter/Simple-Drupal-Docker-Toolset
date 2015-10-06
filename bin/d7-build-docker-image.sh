#!/bin/bash

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)

# PHP 54
dockerfile_folder="${mydir}/../dockerfiles/d7/php54"
docker build -t fin-d7-54 ${dockerfile_folder}

# PHP 5.6
dockerfile_folder="${mydir}/../dockerfiles/d7/php56"
docker build -t fin-d7-56 ${dockerfile_folder}
