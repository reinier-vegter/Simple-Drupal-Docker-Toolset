#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)

. ${mydir}/common.sh

env_vars="-e DOCKERUSER=$(whoami)"
volume_opts=""
link_opts=""
hostname_opts=""
custom_hostnames=""
dns_entries=""
custom_php_ini=""
NO_DRUPAL_CHECK=0
VARNISH_ENABLE=0
MEMCACHED_ENABLE=0
XHGUI_ENABLE=0
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
    image='rvegter/simple-drupal-docker-toolset:php54'
   ;;
  5.6)
    image='rvegter/simple-drupal-docker-toolset:php56'
    ;;
  7.0)
    image='rvegter/simple-drupal-docker-toolset:php70'
    ;;
  *)
    image='rvegter/simple-drupal-docker-toolset:php56'
    PHP_VERSION="5.6"
esac
env_vars=${env_vars}" -e PHP_VERSION="${PHP_VERSION}

# check if this is drupal.
if [ $NO_DRUPAL_CHECK -ne 1 ]; then
  [ ! -f index.php ] && noDrupal
  [ ! -f includes/bootstrap.inc ] && [ ! -f core/includes/bootstrap.inc ] && noDrupal
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
# enable xhgui ?
if [ $XHGUI_ENABLE -eq 1 ]; then
  env_vars=${env_vars}" -e XHGUI_ENABLE=1"
fi

# Add dockerhost to container, if it's running inside virtualbox.
# dockerhost should refer to vbox host, instead of vbox VM.
if [ "$D7_VBOX_IP" != "" ]; then
  echo "Running in vbox, with VM IP $D7_VBOX_IP"
  dockerhost=$(echo $D7_VBOX_IP | sed 's|\.[0-9]\{1,3\}$|.1|g')
  echo "   -> $dockerhost"
  hostname_opts=${hostname_opts}" --add-host dockerhost:${dockerhost}"
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

# Attach mailsink.
mailsink=${datastore_project}/mail
[ ! -d "${mailsink}" ] && mkdir -p "${mailsink}"
volume_opts=${volume_opts}' -v '"${mailsink}:/var/log/mail"

# Add custom php.ini file.
if [ "${custom_php_ini}" != "" ] && [ -f "${custom_php_ini}" ]; then
  [ ! -d ${datastore_project}/php_local_config ] && mkdir -p ${datastore_project}/php_local_config
  [ -f ${datastore_project}/php_local_config/local.ini ] && rm ${datastore_project}/php_local_config/local.ini
  cp "${custom_php_ini}" ${datastore_project}/php_local_config/local.ini
  volume_opts=${volume_opts}' -v '"${datastore_project}/php_local_config:/etc/php5/local.conf.d"
fi

# Check drupal base image
function check_drupal_image() {
  if [ "$(docker images | grep $image)" = "" ]; then
    # build image first.
    "${mydir}/d7-build-docker-image.sh"
  fi
}

# Start / Attach solr container.
d7-solr4-start
link_opts=${link_opts}' --link '"$solr_container_name:solr"

# cleanup if this container does exist but stopped.
container_running=$(docker ps -a --filter "name=$d7_container_name" --filter "status=running" --format "{{.ID}}")
if [ "$container_running" != "" ]; then
  echo "Container already running"
else
  # cleanup if this container does exist but stopped.
  container_exit=$(docker ps -a --filter "name=$d7_container_name" --filter "status=exited" --filter "status=dead" --filter "status=paused" --filter "status=created" --format "{{.ID}}")
  if [ "$container_exit" != "" ]; then
    for cont in ${container_exit[@]}; do
      docker rm ${cont}
    done
  fi

  # Check drupal image.
  # check_drupal_image
  # TODO: should be used for development environment somehow,
  # to make us able to build images local.

  cust_config_folder="${mydir}/../php"
  run="/bin/bash /bootstrap/run-drupal.sh"
  CMD="docker run -d ${link_opts} ${hostname_opts} ${env_vars} --add-host ${container_hostname}:127.0.0.1 ${dns_entries} -v ${cust_config_folder}:/etc/php5/custom.conf.d ${volume_opts} --name ${d7_container_name} -v `pwd`:/var/www ${image} ${run}"
  echo ${CMD}
  ${CMD}
fi

hostname_list_message=""
ip=$(publicIp $d7_container_name)
# add host to hostsfile.
"${mydir}"/d7-hosts-entry.sh add ${ip} ${container_hostname}
if [ $? -ne 0 ]; then
  container_hostname=${ip}
else
  # Add custom hostnames to hostsfile.
  for hostname in ${custom_hostnames[@]}; do
    "${mydir}"/d7-hosts-entry.sh add ${ip} ${hostname}
    hostname_list_message=${hostname_list_message}"\n Additional hostname: ${hostname}"
  done
fi

echo ""
echo " :D7:  Access me on http://$container_hostname/ or $container_hostname (for ssh etc)."
echo " :D7:  my ssh root passwd: 'root' (or just type d7-ssh)"
echo " :D7:  Mailsink located at ${mailsink}"
echo -e ${hostname_list_message}
