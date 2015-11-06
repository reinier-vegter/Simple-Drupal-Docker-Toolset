#!/bin/bash

DOCKERVM=default
if [[ "$(uname -a)" == *"Darwin"* ]]; then
  # OH NO, USING DORA LAPTOP!!
  OSX=1
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
    fi
    # import docker env vars in shell
    eval "$(docker-machine env $DOCKERVM)"
  else
    # import docker env vars in shell
    eval "$env"
  fi

  export D7_VBOX_IP=$(docker-machine ip $DOCKERVM)
fi
