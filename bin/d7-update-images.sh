#!/bin/bash

script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)
. ${mydir}/common.sh

echo ""
echo "This will redownload images if they are updated"
echo "If some download gets stuck for a long time, abort and restart the docker service."
echo "Then, run d7-update-images again"

if [ "$1" != "y" ]; then
  echo "Enter to proceed, or ctr-c to abort."
  read input
fi

# Images to fetch updates for.
images=(
  "rvegter/simple-drupal-docker-toolset:php54"
  "rvegter/simple-drupal-docker-toolset:php56"
  "rvegter/simple-drupal-docker-toolset:php70"
  "twinbit/docker-drupal-solr"
  "jwilder/nginx-proxy"
  "mysql:5.6.26"
)

# Read local (downloaded) images.
local_images=$(docker images)

for image in ${images[@]}; do
  base=$(echo $image | sed 's|:.*||')
  tag=$(echo $image | sed 's|.*:||')

  # No tag specified, base is than image.
  [ "$base" = "" ] && base=$image

  # Only pull image if it's already on this system.
  image_is_local=$(echo -e "${local_images}" | grep '^'$base'.*'$tag)
  if [ "${image_is_local}" != "" ]; then
    echo "Checking $image"
    docker pull ${image}
  else
    echo "Skipping $image"
  fi
  echo ""
done
