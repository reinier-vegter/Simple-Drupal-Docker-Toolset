#!/bin/bash

image='finalist-drupal7'
name='d7'$(pwd | sed 's| |_|g' | sed 's|/|.|g')
docker stop -t 1 ${name}
docker rm ${name}
echo "Container '$name' stopped and removed".
