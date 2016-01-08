#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)

. ${mydir}/common.sh

env_vars="-e DOCKERUSER=$(whoami)"
volume_opts=""
link_opts=""
hostname_opts=""
custom_hostnames=""
NO_DRUPAL_CHECK=0
VARNISH_ENABLE=0
MEMCACHED_ENABLE=0
PHP_VERSION=""

# Check dependency containers etc.
. ${mydir}/docker-custom-config.sh ${mydir}/d7-configs.cfg

# check for custom (project) configs, containers , links etc.
. ${mydir}/docker-custom-config.sh

function noDrupal () {
 echo "This is not a Drupal webroot, can't start."
 cat "$mydir"/finger.txt
 exit 1
}

# Set image w.r.t. php version.
case "$PHP_VERSION" in
  5.4)
    image='fin-d7-54'
   ;;
  5.6)
    image='fin-d7-56'
    ;;
  7.0)
    image='fin-d7-70'
    ;;
  *)
    image='fin-d7-54'
    PHP_VERSION="5.4"
esac
env_vars=${env_vars}" -e PHP_VERSION="${PHP_VERSION}

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
# enable memcached ?
if [ $MEMCACHED_ENABLE -eq 1 ]; then
  env_vars=${env_vars}" -e MEMCACHED_ENABLE=1"
fi

# Generate hostname.
container_hostname="dev.$(basename `pwd`).local"

# Tell proxy container about this host.
env_vars=${env_vars}" -e VIRTUAL_HOST="${container_hostname}

# Add custom hostnames as environmental variables for proxy.
for hostname in ${custom_hostnames[@]}; do
  env_vars=${env_vars}" -e VIRTUAL_HOST="${hostname}
done

# Add Xdebug host ip.
env_vars=${env_vars}" -e XDEBUG_CONFIG='remote_host=dockerhost'"

# check drupal base image
function check_drupal_image() {
  if [ "$(docker images | grep $image)" = "" ]; then
    # build image first.
    "${mydir}/d7-build-docker-image.sh"
  fi
}

# cleanup if this container does exist but stopped.
container_running=$(docker ps -a --filter "name=$d7_container_name" --filter "status=running" --format "{{.ID}}")
if [ "$container_running" != "" ]; then
  echo "Container already running"
else
  # cleanup if this container does exist but stopped.
  container_exit=$(docker ps -a --filter "name=$d7_container_name" --filter "status!=running" --format "{{.ID}}")
  if [ "$container_exit" != "" ]; then
    for cont in ${container_exit[@]}; do
      docker rm ${cont}
    done
  fi

  # Check drupal image.
  check_drupal_image

  cust_config_folder="${mydir}/../php"
  run="/bin/bash /bootstrap/run-drupal.sh"
  CMD="docker run -d ${link_opts} ${hostname_opts} ${env_vars} --add-host ${container_hostname}:127.0.0.1 -v ${cust_config_folder}:/etc/php5/custom.conf.d ${volume_opts} --name ${d7_container_name} -v `pwd`:/var/www ${image} ${run}"
  echo ${CMD}
  ${CMD}
fi

ip=$(publicIp $d7_container_name)
# add host to hostsfile.
"${mydir}"/d7-add-host.sh ${ip} ${container_hostname}
if [ $? -ne 0 ]; then
  container_hostname=${ip}
else
  # Add custom hostnames to hostsfile.
  for hostname in ${custom_hostnames[@]}; do
    "${mydir}"/d7-add-host.sh ${ip} ${hostname}
  done
fi

echo ""
echo " :D7:  Access me on http://$container_hostname/ or $container_hostname (for ssh etc)."
echo " :D7:  my ssh root passwd: 'root'"
