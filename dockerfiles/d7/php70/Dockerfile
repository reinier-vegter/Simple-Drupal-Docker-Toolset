FROM debian:jessie
MAINTAINER Reinier Vegter <hr.vegter@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install system tools.
RUN apt-get update
RUN apt-get install -y \
	vim \
	git \
	wget \
	curl \
	openssh-server \
	net-tools

# Install server packages.
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.list
RUN wget http://www.dotdeb.org/dotdeb.gpg -O - |apt-key add -
RUN apt-get update
RUN apt-get install -y \
	apache2 \
  php7.0-cli \
  php7.0-mysql \
  php7.0-gd \
  php7.0-curl \
  php7.0-ldap \
  php7.0-mcrypt \
  php7.0-json \
  # 	php-soap \
  php7.0-intl \
  libapache2-mod-php7.0 \
    curl \
    openssh-server \
    net-tools \
    memcached \
  #	php5-memcache \
  php7.0-dev

# install xhprof
#RUN pecl config-set preferred_state beta
#RUN pecl install xhprof
#RUN apt-get purge -y php5-dev

# Varnish installation.
RUN apt-get install -y apt-transport-https
RUN curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add -
RUN echo "deb https://repo.varnish-cache.org/debian/ jessie varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list
RUN apt-get update
RUN apt-get install -y varnish
# Make varnish able to start, since using 'ulimit' is usually forbidden from container.
RUN sed -i 's/^ulimit/#ulimit/g' /etc/init.d/varnish
# Put varnish on port 80, instead of 6081
RUN sed -i 's/DAEMON_OPTS="-a :6081/DAEMON_OPTS="-a :80/' /etc/default/varnish

# Cleanup apt cache.
# RUN apt-get clean
# RUN apt-get autoremove
# RUN rm -rf /var/lib/apt/lists/*

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
#
## Setup PHP.
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.0/apache2/php.ini
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.0/cli/php.ini

## Add solr proxy to apache
RUN echo "Listen 8983" >> /etc/apache2/ports.conf
RUN echo "NameVirtualHost *:8983" >> /etc/apache2/ports.conf

# enable mod
RUN a2enmod rewrite
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod ssl

# Setup SSH.
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Enable mysql/apache on boot.
RUN update-rc.d apache2 defaults
RUN mkdir /var/run/sshd

# Let memcached listen on any IP, so it's connectable from outside the container.
RUN sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf
# Disable memcached by default.
RUN update-rc.d memcached disable

## Install Drush 8.
RUN composer global require drush/drush:8.*
RUN composer global update

# Set composer folder, so that non-privileged users (www-data) can use it's content.ADD
RUN mv /root/.composer /opt/composer
RUN ln -s /opt/composer /root/.composer

# Unfortunately, adding the composer vendor dir to the PATH doesn't seem to work. So:
RUN ln -s /opt/composer/vendor/bin/drush /usr/local/bin/drush

EXPOSE 80 443 22 11211
