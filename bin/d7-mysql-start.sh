#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

root_passwd=root
name='docker.mysql'
image='mysql:5.6.26'
container_hostname='mysql-docker.dev'
local_data_folder=${HOME}'/.drupal_docker_toolset/mysql_data'

# Create datafolder if it doesn't exist.
[ ! -d ${local_data_folder} ] && mkdir -p ${local_data_folder}

# cleanup if this container does exist but stopped.
container_running=$(docker ps -a --filter "name=$name" --filter "status=running" --format "{{.ID}}")
if [ "$container_running" != "" ]; then
  echo "Container already running"
else
  container_stopped=$(docker ps -a --filter "name=$name" --filter "status=exited" --format "{{.ID}}")
  if [ "$container_stopped" != "" ]; then
    docker start "$container_stopped"
  else

    # Add config file.
    cust_config_folder="${mydir}/../mysql"

    # Expose port on machine, if 'this' is a vbox machine.
    exposed_port_opts=""
    if [ "$D7_VBOX_IP" != "" ]; then
      exposed_port_opts="-p 3306:3306"
    fi
    bootstrap="${mydir}/../dockerfiles/mysql/bootstrap"
    cmd="/bootstrap/start-mysql.sh"
    run="docker run --name $name --entrypoint ${cmd} -v ${local_data_folder}:/var/lib/mysql -v ${bootstrap}:/bootstrap -v ${cust_config_folder}:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=$root_passwd ${exposed_port_opts} -d $image"
    echo ${run}
    ${run}
  fi
fi

ip=$(publicIp $name)
"${mydir}"/d7-add-host.sh ${ip} ${container_hostname}
if [ $? -ne 0 ]; then
  container_hostname=${ip}
fi

echo " :MYSQL:  Access me on ${container_hostname}"":3306"
echo " :MYSQL:  MySQL root password: $root_passwd"
