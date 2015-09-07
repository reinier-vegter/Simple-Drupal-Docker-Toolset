#!/bin/bash

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)

## Examples:

# CUST_DEPENDENCIES=(
#   "docker.mysql:${mydir}/d7-mysql-start.sh"
#   "docker.solr4:${mydir}/d7-solr4-start.sh"
# )
# CUST_LINK=(
#   "docker.mysql:mysql-docker.dev"
#   "docker.solr4:solr4-docker.dev"
# )
# CUST_VOL="/opt/simplesamlphp:/opt/simplesamlphp1"

# Include project config.
CUST_LINK=""
CUST_VOL=""
CUST_DEPENDENCIES=""

if [ "$1" != "" ] && [ -f "$1" ]; then
  source "$1"
elif [ -f ./.d7-docker.conf ]; then
  source ./.d7-docker.conf
fi

# read custom docker links.
if [ "$CUST_LINK" != "" ]; then
  for link in ${CUST_LINK[@]}; do
    link_opts=${link_opts}' --link '"$link"
  done
fi

# read custom docker volume mounts.
if [ "$CUST_VOL" != "" ]; then
  for volume in ${CUST_VOL[@]}; do
    volume_opts=${volume_opts}' -v '"$link"
  done
fi

# read custom docker dependencies.
if [ "$CUST_DEPENDENCIES" != "" ]; then
  for dependency in ${CUST_DEPENDENCIES[@]}; do
    container_name=$(echo "$dependency" | sed 's/:.*//g' | sed 's| ||g')
    start_command=$(echo "$dependency" | sed 's/.*://g' | sed 's| ||g')
    dep_running=$(docker ps -a --filter "name=$container_name" --filter "status=running" --format "{{.ID}}")
    if [ "$dep_running" = "" ]; then
      echo ""
      echo "========"
      echo "Need to start $dep container first"
      ${start_command}
      echo ""
    fi
  done
fi
