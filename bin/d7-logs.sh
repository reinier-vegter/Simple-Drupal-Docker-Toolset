#!/bin/bash

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)
name='d7'$(pwd | sed 's| |_|g' | sed 's|/|.|g')
docker logs -f ${name}
