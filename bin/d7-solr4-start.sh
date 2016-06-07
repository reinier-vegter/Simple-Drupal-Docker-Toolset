#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

# Init values.
volume_opts=""
SOLR_CONF_OVERRIDES=""

# Container name and base values.
solr_container_name=${d7_container_name}".solr4"
image='twinbit/docker-drupal-solr'
solr_container_hostname='solr4-docker.dev'
hostsfile=/etc/hosts

# Create solr data folder.
solr_store=${datastore_project}'/solr'
[ ! -d "${solr_store}" ] && mkdir -p "${solr_store}"
# In-container data-folder
container_data_folder='/opt/solr/example/solr/collection1/data'
volume_opts=${volume_opts}" -v ${solr_store}:${container_data_folder}"

# check for custom (project) configs, containers , links etc.
. ${mydir}/docker-custom-config.sh

# Search for solr config folder and attach,
# unless a custom folder was provided.
solr_conf=""
if [ "$SOLR_CONF_OVERRIDES" != "" ]; then
  solr_conf=${SOLR_CONF_OVERRIDES}
else
  folder=$(find ./ -type d -name "search_api_solr" | head -n 1)
  if [ "$folder" != "" ]; then
    conf="$folder/solr-conf/4.x"
    if [ -d "$conf" ]; then
      solr_conf=${conf}
    fi
  fi
fi
if [ "${solr_conf}" != "" ]; then
  # Get absolute path.
  # Docker won't handle relative paths.
  oldpwd=$(pwd)
  cd "${solr_conf}" && solr_conf=$(pwd)
  cd "${oldpwd}"
  echo " :SOLR:  Using solr config files from ${solr_conf}"
  volume_opts=${volume_opts}' -v '"${solr_conf}:/opt/custom_conf"
fi

# Set entrypoint (start command).
bootstrap="${mydir}/../dockerfiles/solr/bootstrap"
volume_opts=${volume_opts}" -v ${bootstrap}:/bootstrap"
cmd='/bootstrap/start-solr.sh'

# cleanup if this container does exist but stopped.
container_running=$(docker ps -a --filter "name=$solr_container_name" --filter "status=running" --format "{{.ID}}")
if [ "$container_running" != "" ]; then
  echo "Container already running"
else
  container_stopped=$(docker ps -a --filter "name=$solr_container_name" --filter "status=exited" --format "{{.ID}}")
  if [ "$container_stopped" != "" ]; then
    docker start "$container_stopped"
  else
    docker run ${volume_opts} --entrypoint ${cmd} --name "$solr_container_name" -d "$image"
  fi
fi

ip=$(publicIp $solr_container_name)
"${mydir}"/d7-hosts-entry.sh add ${ip} ${solr_container_hostname}
if [ $? -ne 0 ]; then
  solr_container_hostname=${ip}
fi

echo " :SOLR:  Access me on ${solr_container_hostname}:8983/solr"
