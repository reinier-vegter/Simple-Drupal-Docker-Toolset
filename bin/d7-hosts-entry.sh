#!/bin/bash

# Global vars.
hostsfile=/etc/hosts
op=$1
tag="# generated by d7-docker"

# Remove hostname from hostsfile.
# Usage: remove [hostname]
function remove() {
  if [ "$(cat ${hostsfile} | grep $1)" != "" ]; then
    cat ${hostsfile} | grep -v "\s$1\s.*${tag}" > /tmp/.hostsfile
    cp /tmp/.hostsfile ${hostsfile}
  fi
}

# Add hostname to hosts file.
# Usage: add [ip] [hostname]
function add() {
  hostfile_entry="$1 $2 ${tag}"
  echo ${hostfile_entry} >> ${hostsfile}
}

# Remove all hosts-entries generated by this toolset.
# Usage: cleanup
function cleanup() {
  content=$(cat ${hostsfile} | grep "${tag}")
  if [ "${content}" != "" ]; then
    cat ${hostsfile} | grep -v "${tag}" > /tmp/.hostsfile
    cp /tmp/.hostsfile ${hostsfile}
  fi
}

# Print help message.
function help() {
    echo ""
    echo "============================================================================"
    echo "Usage:"
    echo "$0 add [ip] [hostname]"
    echo "$0 remove [hostname] # Dangerous!! Works on filtering, so if you supply '.', almost everything will be removed!"
    echo "$0 cleanup # remove all generated hostsfile entries"
    exit 1
}

# Print install message.
function help_install() {
  echo ""
  echo "============================================================================"
  echo "I cannot write your hostsfile, so cannot provide you with a nice hostname."
  echo "Please enter the following commands:"

  if [ $OSX -eq 1 ]; then
    echo "    sudo dseditgroup -o edit -a $(whoami) -t user wheel"
    echo "    sudo chmod 664 /etc/hosts"
  else
    echo "    chown root:$(whoami) /etc/hosts"
    echo "    chmod 664 /etc/hosts"
  fi

  echo " in order to fix this..."
  echo ""
  exit 1
}

# Check if we can write hosts file.
if [ -w ${hostsfile} ]; then
  if [ "$op" == "add" ]; then
    ip=$2
    hostname=$3

    # Check.
    [ "$ip" == "" ] && help
    [ "$hostname" == "" ] && help

    remove ${hostname}
    add ${ip} ${hostname}
  elif [ "$op" == "remove" ]; then
    hostname=$2

    # Check.
    [ "$hostname" == "" ] && help

    remove ${hostname}
  elif [ "$op" == "cleanup" ]; then
    cleanup
  else
    help
  fi
else
  help_install
fi
