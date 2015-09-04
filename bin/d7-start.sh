#!/bin/bash

env_vars="-e DOCKERUSER=$(whoami)"

mysql_link='docker.mysql'
mysql_hostname='mysql-docker.dev'

solr_link='docker.solr4'
solr_hostname='solr4-docker.dev'

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)

function noDrupal () {
 echo "This is not a Drupal webroot, can't start."
 cat "$mydir"/finger.txt
 exit 1
}

[ ! -f index.php ] && noDrupal
[ ! -f includes/bootstrap.inc ] && noDrupal

image='finalist-drupal7'
name='d7'$(pwd | sed 's| |_|g' | sed 's|/|.|g')

link_opts=""
if [ "$mysql_link" != "" ]; then
  link_opts=${link_opts}' --link '${mysql_link}':'${mysql_hostname}
fi
if [ "$solr_link" != "" ]; then
  link_opts=${link_opts}' --link '${solr_link}':'${solr_hostname}
fi

# generate hostname.
container_hostname="dev.$(basename `pwd`).local"

# check containers that we depend on.
function check_dependency() {
    dep=$1
    script=$2
    dep_running=$(docker ps -a --filter "name=$dep" --filter "status=running" --format "{{.ID}}")
    if [ "$dep_running" = "" ]; then
      echo "Need to start $dep container first"
      ${script}
    fi
}

# check drupal base image
function check_drupal_image() {
  if [ "$(docker images | grep $image)" = "" ]; then
    # build image first.
    "${mydir}/d7-build-docker-image.sh"
  fi
}

# cleanup if this container does exist but stopped.
container_running=$(docker ps -a --filter "name=$name" --filter "status=running" --format "{{.ID}}")
if [ "$container_running" != "" ]; then
  echo "Container already running"
else
  # cleanup if this container does exist but stopped.
  container_exit=$(docker ps -a --filter "name=$name" --filter "status!=running" --format "{{.ID}}")
  if [ "$container_exit" != "" ]; then
    for cont in ${container_exit[@]}; do
      docker rm ${cont}
    done
  fi

  # check mysql docker container first.
  if [ "$mysql_link" != "" ]; then
    check_dependency ${mysql_link} ${mydir}/d7-mysql-start.sh
  fi
  # check mysql docker container first.
  if [ "$solr_link" != "" ]; then
    check_dependency ${solr_link} ${mydir}/d7-solr4-start.sh
  fi

  check_drupal_image

  cust_config_folder="${mydir}/../php"
  docker run -d ${link_opts} ${env_vars} --add-host ${container_hostname}:127.0.0.1 -v ${cust_config_folder}:/etc/php5/custom.conf.d --name ${name} -v `pwd`:/var/www ${image}
fi

ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${name})

# add host to hostsfile.
"${mydir}"/d7-add-host.sh ${ip} ${container_hostname}
if [ $? -ne 0 ]; then
  container_hostname=${ip}
fi

echo "Access me on http://$container_hostname/ or $container_hostname (for ssh etc)."
echo "my ssh root passwd: 'root'"
