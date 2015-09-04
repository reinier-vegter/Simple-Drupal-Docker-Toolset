FROM debian:wheezy
MAINTAINER Reinier Vegter <hr.vegter@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install packages.
RUN apt-get update
RUN apt-get install -y \
	vim \
	git \
	apache2 \
	php-apc \
	php5-fpm \
	php5-cli \
	php5-mysql \
	php5-gd \
	php5-curl \
	php5-ldap \
	php5-mcrypt \
	php-services-json \
	php-soap \
	php5-intl \
	libapache2-mod-php5 \
	curl \
	mysql-server \
	mysql-client \
	openssh-server \
	wget \
	net-tools
RUN apt-get clean

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Setup PHP.
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php5/apache2/php.ini
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php5/cli/php.ini

# Setup Apache.
# In order to run our Simpletest tests, we need to make Apache
# listen on the same port as the one we forwarded. Because we use
# 8080 by default, we set it up for that port.
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default

# RUN echo "Listen 8080" >> /etc/apache2/ports.conf
# RUN sed -i 's/VirtualHost *:80/VirtualHost */' /etc/apache2/sites-available/default

## Add solr proxy to apache
RUN echo "Listen 8983" >> /etc/apache2/ports.conf
RUN echo "NameVirtualHost *:8983" >> /etc/apache2/ports.conf

# enable mod
RUN a2enmod rewrite
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod ssl

# enable SSL vhost
RUN a2ensite default-ssl

# Setup SSH.
RUN echo 'root:root' | chpasswd
## RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
## RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
## RUN mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys
## RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Enable mysql/apache on boot.
RUN update-rc.d apache2 defaults
RUN mkdir /var/run/sshd

# Setup Supervisor.
## RUN echo -e '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
## RUN echo -e '[program:mysql]\ncommand=/usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf
## RUN echo -e '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf
## RUN echo -e '[program:blackfire]\ncommand=/usr/local/bin/launch-blackfire\n\n' >> /etc/supervisor/supervisord.conf

# Install Drush 7.
RUN composer global require drush/drush:7.*
RUN composer global update
# Unfortunately, adding the composer vendor dir to the PATH doesn't seem to work. So:
RUN ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

ADD ./bootstrap /bootstrap
RUN cp /bootstrap/solr-proxy.vhost /etc/apache2/sites-enabled/
RUN chmod +x /bootstrap/*.sh
WORKDIR /bootstrap

EXPOSE 80 443 22
CMD ./run-drupal.sh
# CMD /usr/sbin/sshd -D
