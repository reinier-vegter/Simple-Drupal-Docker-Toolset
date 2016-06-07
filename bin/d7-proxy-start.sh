#!/bin/bash

# Call with parameter "rebuild" to rebuild proxy image.

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)

. ${mydir}/common.sh

image='jwilder/nginx-proxy:0.2.0'

# generate hostname.
container_hostname="dev.proxy.local"

# cleanup if this container does exist but stopped.
container_running=$(docker ps -a --filter "name=$proxy_container_name" --filter "status=running" --format "{{.ID}}")
if [ "$container_running" != "" ]; then
  echo "Container already running"
  exit 1
else
  # cleanup if this container does exist but stopped.
  container_exit=$(docker ps -a --filter "name=$proxy_container_name" --filter "status=exited" --filter "status=dead" --filter "status=paused" --filter "status=created" --format "{{.ID}}")
  if [ "$container_exit" != "" ]; then
    for cont in ${container_exit[@]}; do
      docker rm ${cont}
    done
  fi
fi

CMD="docker run -v /var/run/docker.sock:/tmp/docker.sock:ro -d --name ${proxy_container_name} -p 80:80 -p 443:443 ${image}"
echo ${CMD}
${CMD}

ip=$(publicIp $proxy_container_name)
"${mydir}"/d7-hosts-entry.sh add ${ip} ${container_hostname}
if [ $? -ne 0 ]; then
  container_hostname=${ip}
fi
echo " :PROXY:  Access me on ${container_hostname} (ports 80,443)"
