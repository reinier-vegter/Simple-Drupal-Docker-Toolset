FROM debian:wheezy
MAINTAINER Reinier Vegter <hr.vegter@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install packages.
RUN apt-get update && \
  apt-get install -y  tinyproxy \
	&& rm -r /var/lib/apt/lists/*


EXPOSE 80 443
CMD service tinyproxy start; tail -f /var/log/tinyproxy/tinyproxy.log
