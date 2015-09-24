#!/bin/bash


binary_path='/bin'
mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)

# scripts to symlink.
scripts=(
  'd7-cleanup.sh'
  'd7-build-docker-image.sh'
  'd7-start.sh'
  'd7-stop.sh'
  'd7-stop-all.sh'
  'd7-mysql-start.sh'
  'd7-mysql-stop.sh'
  'd7-status.sh'
  'd7-solr4-start.sh'
  'd7-solr4-stop.sh'
  'd7-logs.sh'
  'd7-help.sh'
)

me=$(whoami)
[ "$me" != "root" ] && echo "Must be root to do this!" && exit 1

echo "Do you want me to symlink my shell-scripts to your /bin folder, and make them system-wide executable ?"
echo "Note that you must leave 'this' folder in place. If you move it, re-run this script again."
echo "Enter to proceed, or ctr-c to abort."

read input

oldpwd=$(pwd)

# symlink to /bin folder.
cd ${mydir}
for file in ${scripts[@]}; do
if [ -f "${mydir}/$file" ]; then
   link_name="${binary_path}/${file%.*}"
   [ -f "${link_name}" ] && rm "${link_name}"
   ln -s "${mydir}/$file" "${link_name}"
   echo " -> ${file%.*}"
 fi
done

## copy dockerfile in /etc folder, so we can rebuild it afterwards.
#[ ! -d /etc/d7-docker ] && mkdir /etc/d7-docker
#[ -f /etc/d7-docker/Dockerfile ] && rm /etc/d7-docker/Dockerfile
#cp "${mydir}/../dockerfiles/d7/Dockerfile" /etc/d7-docker/Dockerfile

cd "${oldpwd}"