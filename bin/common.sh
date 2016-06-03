#!/bin/bash

# Available variables:
# - ${scriptbase}             : this bin folder
# - ${base}                   : base folder of this project (where README can be found)
# - ${d7_container_name}      : Drupal container name based on folder etc.
# - ${OSX}                    : 1 if this is an OSX machine, 0 otherwise.
# - ${proxy_container_name}   : Name of proxy container.
#
# Available functions:
# - publicIp              : Get container IP, or VBox ip (if using OSX).
#                          : Usage: ip=$(publicIp [container name])

# get my dir.
script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)

scriptbase=$mydir
base=$(dirname "$scriptbase")

# Fix OSX stuff, if needed.
# Set default env var 'OSX'.
[ "$OSX" = "" ] && export OSX=0
if [[ "$(uname -a)" == *"Darwin"* ]]; then
  # OH NO, USING DORA LAPTOP!!
  echo "Oh joy, you're using a mac"
  export OSX=1

  # Docker machine folder to use.
  export DOCKER_MACHINE_DIR=${mydir}/.docker_machine

  if [ "$1" != "no-docker-check" ]; then
    . ${scriptbase}/osx-wrap-start.sh
  fi
fi

# Generate container name.
base_name='d7'$(pwd | sed 's| |_|g' | sed 's|/|.|g')
d7_container_name=${base_name}".php"
solr_container_name=${base_name}".solr4"
solr_container_hostname="dev.$(basename `pwd`).solr.local"

# Global data folder.
datastore=${HOME}'/.drupal_docker_toolset'
[ ! -d ${datastore} ] && mkdir -p ${datastore}

# Generate data storage for 'this' project.
datastore_project=$(pwd)'/.drupal_docker_toolset_project'
[ ! -d ${datastore_project} ] && mkdir -p ${datastore_project}

function publicIp() {
  name=$1
  # Vbox or native ip ?
  if [ "$D7_VBOX_IP" != "" ]; then
    ip=$D7_VBOX_IP
  else
    ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${name})
  fi
  echo ${ip}
}

proxy_container_name='docker.open-proxy'
