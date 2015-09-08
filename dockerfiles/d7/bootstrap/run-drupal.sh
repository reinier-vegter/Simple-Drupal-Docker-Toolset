#!/bin/bash

# ===================== Give host a hostname ============
SED="$(which sed)"
NETSTAT="$(which netstat)"
GREP="$(which grep)"
AWK="$(which awk)"
CAT="$(which cat)"

$SED '/dockerhost$/d' /etc/hosts > /etc/hosts.tmp
DOCKERHOST="$($NETSTAT -nr | $GREP '^0\.0\.0\.0' | $AWK '{print $2}')"
echo "$DOCKERHOST dockerhost" >> /etc/hosts.tmp
$CAT /etc/hosts.tmp > /etc/hosts
rm -rf /etc/hosts.tmp
# ==

# ==================== Run apache as 'us' ==============
if [ "$DOCKERUSER" != "" ]; then
  if [ "$(cat /etc/passwd | grep $DOCKERUSER)" = "" ]; then
    # add user to system.
    groupadd $DOCKERUSER
    useradd -g $DOCKERUSER $DOCKERUSER
    echo "Created user $DOCKERUSER on the system"

    # fix apache user.
    sed -i "s|.*APACHE_RUN_USER=.*$|export APACHE_RUN_USER=$DOCKERUSER|g" /etc/apache2/envvars
    sed -i "s|.*APACHE_RUN_GROUP=.*$|export APACHE_RUN_GROUP=$DOCKERUSER|g" /etc/apache2/envvars
    chown -R $DOCKERUSER:$DOCKERUSER /var/lock/apache2
    chown -R $DOCKERUSER:$DOCKERUSER /var/log/apache2
  fi
fi
# ==

# =================== Use custom php config ============
if [ -d /etc/php5/custom.conf.d ]; then
  ln -s /etc/php5/custom.conf.d/custom-config.ini /etc/php5/conf.d/
fi
# ==

# =================== Enable varnish ? =================
if [ $VARNISH_ENABLE -eq 1 ]; then
  service varnish start
  # Run apache on port 90 instead of 80.
  sed -i 's/ 80$/ 90/g' /etc/apache2/ports.conf
  sed -i 's/:80>/:90>/g' /etc/apache2/sites-available/*
fi
# ==

service apache2 start
/usr/sbin/sshd -D
