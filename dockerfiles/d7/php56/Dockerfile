FROM rvegter/simple-drupal-docker-toolset:php54
MAINTAINER Reinier Vegter <hr.vegter@gmail.com>

RUN echo "deb http://packages.dotdeb.org wheezy-php56 all" >> /etc/apt/sources.list.d/dotdeb.list
RUN echo "deb-src http://packages.dotdeb.org wheezy-php56 all" >> /etc/apt/sources.list.d/dotdeb.list

RUN wget http://www.dotdeb.org/dotdeb.gpg -O - |apt-key add -

RUN apt-get update
RUN apt-get dist-upgrade -y

## install xhprof
RUN apt-get install -y php5-dev make
RUN pecl config-set preferred_state beta
RUN pecl uninstall xhprof
RUN pecl install xhprof
RUN pecl uninstall mongo
RUN pecl install mongo

# Cleanup
RUN apt-get purge -y php5-dev make

# Cleanup apt cache.
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
