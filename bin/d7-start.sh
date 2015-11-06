#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)

. ${mydir}/common.sh

env_vars="-e DOCKERUSER=$(whoami)"
volume_opts=""
link_opts=""
NO_DRUPAL_CHECK=0
VARNISH_ENABLE=0

# Check dependency containers etc.
. ${mydir}/docker-custom-config.sh ${mydir}/d7-configs.cfg

# check for custom (project) configs, containers , links etc.
. ${mydir}/docker-custom-config.sh

function noDrupal () {
 echo "This is not a Drupal webroot, can't start."
 cat "$mydir"/finger.txt
 exit 1
}

# check if this is drupal.
if [ $NO_DRUPAL_CHECK -ne 1 ]; then
  [ ! -f index.php ] && noDrupal
  [ ! -f includes/bootstrap.inc ] && noDrupal
else
  echo "Not checking if this is actually a Drupal webroot!"
fi

# enable varnish ?
if [ $VARNISH_ENABLE -eq 1 ]; then
  env_vars=${env_vars}" -e VARNISH_ENABLE=1"
fi

image='finalist-drupal7'

# generate hostname.
container_hostname="dev-$(basename `pwd`)-local"
name=$container_hostname

# Tell proxy container about this host.
env_vars=${env_vars}" -e VIRTUAL_HOST="${container_hostname}

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

  # Check drupal image.
  check_drupal_image

  cust_config_folder="${mydir}/../php"
  CMD="docker run -d ${link_opts} ${env_vars} --add-host ${container_hostname}:127.0.0.1 -v ${cust_config_folder}:/etc/php5/custom.conf.d ${volume_opts} --name ${name} -v `pwd`:/var/www ${image}"
  echo ${CMD}
  ${CMD}
fi

# Vbox or native ip ?
if [ "$D7_VBOX_IP" != "" ]; then
  ip=$D7_VBOX_IP
else
  ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${name})
fi

# add host to hostsfile.
"${mydir}"/d7-add-host.sh ${ip} ${container_hostname}
if [ $? -ne 0 ]; then
  container_hostname=${ip}
fi

echo ""
echo " :D7:  Access me on http://$container_hostname/ or $container_hostname (for ssh etc)."
echo " :D7:  my ssh root passwd: 'root'"
