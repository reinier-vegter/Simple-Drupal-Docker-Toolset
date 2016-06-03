#!/bin/bash

# Available vars:
# - DOCKER_MACHINE_DIR

which docker-machine > /dev/null
if [ $? -ne 0 ]; then
  sudo su root -c "curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` >/usr/local/bin/docker-machine"
  sudo su root -c "chmod +x /usr/local/bin/docker-machine"
fi

docker-machine -v


DOCKERVM=default
env=$(docker-machine env $DOCKERVM)
if [ $? -ne 0 ]; then
  # docker VM not running
  docker-machine inspect $DOCKERVM > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    # create vm
    docker-machine create --driver virtualbox $DOCKERVM
  else
    # start vm
    docker-machine start $DOCKERVM
    # Turn vboxsf mounts into NFS.
    docker-machine-nfs $DOCKERVM
  fi
  # import docker env vars in shell
  eval "$(docker-machine env $DOCKERVM)"
else
  # import docker env vars in shell
  eval "$env"
fi

export D7_VBOX_IP=$(docker-machine ip $DOCKERVM)
