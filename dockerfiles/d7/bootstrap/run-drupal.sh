#!/bin/bash

# Prepare stuff.
cd /bootstrap
chmod +x /bootstrap/*.sh /bootstrap/sendmail
cp /bootstrap/solr-proxy.vhost /etc/apache2/sites-enabled/
cp /bootstrap/varnish-default.vcl /etc/varnish/default.vcl

# Add mailsink.
# Echo's mail into /var/log/mail
ln -s /bootstrap/sendmail /bin/sendmail

# ===================== Give host a hostname unless it's already known (on a mac) ============
SED="$(which sed)"
NETSTAT="$(which netstat)"
GREP="$(which grep)"
AWK="$(which awk)"
CAT="$(which cat)"

host_known=$($CAT /etc/hosts | grep dockerhost)
if [ "${host_known}" = "" ]; then
  $SED '/dockerhost$/d' /etc/hosts > /etc/hosts.tmp
  DOCKERHOST="$($NETSTAT -nr | $GREP '^0\.0\.0\.0' | $AWK '{print $2}')"
  echo "$DOCKERHOST dockerhost" >> /etc/hosts.tmp
  $CAT /etc/hosts.tmp > /etc/hosts
  rm -rf /etc/hosts.tmp
fi
# ==

# ==================== Set apache vhost, if necessary ==
  if [ "$PHP_VERSION" = "7.0" ]; then
    rm /etc/apache2/sites-available/000-default.conf
    ln -s /bootstrap/php7.default.vhost /etc/apache2/sites-available/000-default.conf
  else
    if [ $XHGUI_ENABLE -eq 1 ]; then
      rm /etc/apache2/sites-available/default
      ln -s /bootstrap/php5.default.xhgui.vhost /etc/apache2/sites-available/default
    else
      rm /etc/apache2/sites-available/default
      ln -s /bootstrap/php5.default.vhost /etc/apache2/sites-available/default
    fi
  fi
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
  ln -s /etc/php5/custom.conf.d/custom-config.ini /etc/php5/cli/conf.d/
  ln -s /etc/php5/custom.conf.d/custom-config.ini /etc/php5/apache2/conf.d/
fi
if [ -d /etc/php/7.0 ]; then
  ln -s /etc/php5/custom.conf.d/custom-config.php70.ini /etc/php/7.0/apache2/conf.d/
  ln -s /etc/php5/custom.conf.d/custom-config.php70.ini /etc/php/7.0/cli/conf.d/
fi
# ==

# =================== Enable varnish ? =================
if [ $VARNISH_ENABLE -eq 1 ]; then
  # Do not run varnish yet, or it will show 'backend down' on first start.
  # Run apache on port 90 instead of 80.
  sed -i 's/ 80$/ 90/g' /etc/apache2/ports.conf
  sed -i 's/:80$/:90/g' /etc/apache2/ports.conf
  sed -i 's/:80>/:90>/g' /etc/apache2/sites-available/*
fi
# ==

# ================== Enable memcache D ? ===============
if [ $MEMCACHED_ENABLE -eq 1 ]; then
  service memcached start
fi
# ==

# ================== Enable xhgui ? ====================
if [ $XHGUI_ENABLE -eq 1 ]; then
  mkdir /tmp/xhprof
  service mongodb start
  cp /bootstrap/xhgui.config.php /var/www-xhgui/config/config.php
  chmod -R 777 /var/www-xhgui/cache
  ln -s /var/www-xhgui /var/www/xhgui
else
  rm -rf /var/www-xhgui
fi
# ==


# =================== Enable SSL proxy =================
  ln -s /bootstrap/ssl.vhost /etc/apache2/sites-enabled/ssl-proxy
# ==

# =================== Set php timezone =================
  echo "date.timezone = $(cat /etc/timezone)" >> /etc/php5/apache2/php.ini
# ==

service apache2 start
[ $VARNISH_ENABLE -eq 1 ] && service varnish start
/usr/sbin/sshd
tail -f /var/log/apache2/*log /var/log/syslog
