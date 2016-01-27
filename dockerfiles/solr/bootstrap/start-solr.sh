#!/bin/bash

command='java -Xmx1024m -DSTOP.PORT=8079 -DSTOP.KEY=stopkey -jar start.jar'

# Add custom Drupal configuration files.
if [ -d /opt/custom_conf ]; then
  cp -fr /opt/custom_conf/* solr/collection1/conf/
fi

# Start.
${command}
