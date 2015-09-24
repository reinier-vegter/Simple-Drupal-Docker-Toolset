#!/bin/bash

mydir=$(cd `dirname $(realpath "${BASH_SOURCE[0]}")` && pwd)
cat ${mydir}/../README
