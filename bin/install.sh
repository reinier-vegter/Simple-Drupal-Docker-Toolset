#!/bin/bash


binary_path='/bin'
script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)

. ${mydir}/common.sh no-docker-check

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
  'd7-proxy-start.sh'
  'd7-proxy-stop.sh'
  'd7-ssh.sh'
  'd7-update-images.sh'
)

me=$(whoami)
[ "$me" != "root" ] && echo "Must be root to do this!" && exit 1

echo "Do you want me to symlink my shell-scripts to your /bin folder, and make them system-wide executable ?"
echo "Note that you must leave 'this' folder in place. If you move it, re-run this script again."

if [ $OSX -eq 1 ]; then
  echo "Furthermore, I need to install the docker-machine-nfs script from https://github.com/adlogix/docker-machine-nfs"
fi
echo "Enter to proceed, or ctr-c to abort."

read input

oldpwd=$(pwd)

# symlink to /bin folder.
cd ${mydir}
for file in ${scripts[@]}; do
if [ -f "${mydir}/$file" ]; then
   link_name="${binary_path}/${file%.*}"
   [ -L "${link_name}" ] && rm "${link_name}"
   ln -s "${mydir}/$file" "${link_name}"
   echo " -> ${file%.*}"
 fi
done
cd "${oldpwd}"

# Install docker-machine-nfs script.
if [ $OSX -eq 1 ]; then
  curl https://raw.githubusercontent.com/adlogix/docker-machine-nfs/master/docker-machine-nfs.sh |
  sudo tee /usr/local/bin/docker-machine-nfs > /dev/null && \
  sudo chmod +x /usr/local/bin/docker-machine-nfs
fi

# Update images if needed.
d7-update-images y
