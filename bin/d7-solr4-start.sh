#!/bin/bash

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)

command='-Xmx1024m -DSTOP.PORT=8079 -DSTOP.KEY=stopkey -jar start.jar'
name='docker.solr4'
image='twinbit/docker-drupal-solr'
container_hostname='solr4-docker.dev'
hostsfile=/etc/hosts

# cleanup if this container does exist but stopped.
container_running=$(docker ps -a --filter "name=$name" --filter "status=running" --format "{{.ID}}")
if [ "$container_running" != "" ]; then
  echo "Container already running"
else
  container_stopped=$(docker ps -a --filter "name=$name" --filter "status=exited" --format "{{.ID}}")
  if [ "$container_stopped" != "" ]; then
    docker start "$container_stopped"
  else
    docker run --name "$name" -d "$image" ${command}
  fi
fi

ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${name})
"${mydir}"/d7-add-host.sh ${ip} ${container_hostname}
if [ $? -ne 0 ]; then
  container_hostname=${ip}
fi

echo " :SOLR:  Access me on ${container_hostname}:8983/solr"
