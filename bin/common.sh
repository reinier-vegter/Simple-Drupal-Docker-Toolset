#!/bin/bash

# available stuff:
# - realpath [whatever]
# - ${scriptbase}  : this bin folder
# - ${base}        : base folder of this project (where README can be found)

# get my dir.
script=$(readlink -n $0 || echo "$0")
mydir=$(cd `dirname "$script"` && pwd -P)

scriptbase=$mydir
base=$(dirname "$scriptbase")

# Fix OSX stuff, if needed
if [ "$1" != "no-docker-check" ]; then
  . ${scriptbase}/osx-wrap-start.sh
fi
