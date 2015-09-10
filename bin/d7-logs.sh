#!/bin/bash

if [ "$1" != "" ]; then
  tail=$1
else
  tail=100
fi

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)
name='d7'$(pwd | sed 's| |_|g' | sed 's|/|.|g')
docker logs --tail=$tail -f ${name}

