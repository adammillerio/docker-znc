# Dockerfile for the ZNC IRC Bouncer
# Author: Adam Miller <adam@adammiller.io>
# Based off of jimeh/docker-znc
# Run after build with:
# docker run -d -p <Web port>:8080 -p <IRC Port>:6697 -v "/path/to/znc/data:/opt/znc-data:rw" --restart=always --name znc aemiller/znc

FROM ubuntu:18.04
LABEL maintainer="adammillerio"

# Noninteractive debconfig
ENV DEBIAN_FRONTEND noninteractive

# Specify the version of ZNC to be downloaded, as well as ZNC palaver
ENV ZNC_VERSION 1.7.5
ENV ZNC_PALAVER_VERSION=1.1.2

# Create a new user account with UID/GID of at least 10000.
# This makes it easier to keep host and docker accounts apart
RUN useradd --home /opt/znc-data -M znc -K UID_MIN=10000 -K GID_MIN=10000 && \
	mkdir -p /opt/znc-data && chown znc /opt/znc-data && chmod 0770 /opt/znc-data

# Install build dependencies, download znc, and compile it
RUN apt-get update \
	&& apt-get install -y sudo wget build-essential libssl-dev libperl-dev \
			   pkg-config swig3.0 libicu-dev ca-certificates \
	&& mkdir -p /src \
	&& cd /src \
	&& wget "http://znc.in/releases/archive/znc-${ZNC_VERSION}.tar.gz" \
	&& tar -zxf "znc-${ZNC_VERSION}.tar.gz" \
	&& cd "znc-${ZNC_VERSION}" \
	&& ./configure --disable-ipv6 \
	&& make \
	&& make install \
	&& apt-get clean \
	&& rm -rf /src* /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build and install znc-palaver
RUN mkdir -p src \
	&& cd /src \
	&& wget "https://github.com/cocodelabs/znc-palaver/archive/${ZNC_PALAVER_VERSION}.tar.gz" \
	&& tar -zxf "${ZNC_PALAVER_VERSION}.tar.gz" \
	&& cd "znc-palaver-${ZNC_PALAVER_VERSION}" \
	&& make \
	&& cp palaver.so "/usr/local/lib/znc/" \
	&& rm -rf /src*

# Build and install clientaway
RUN mkdir -p src \
	&& cd /src \
	&& wget "https://github.com/adammillerio/znc-contrib/archive/master.tar.gz" \
	&& tar -zxf "master.tar.gz" \
	&& cd "znc-contrib-master" \
	&& make clientaway \
	&& cp clientaway.so "/usr/local/lib/znc/" \
	&& rm -rf /src*

# Add the default configuration and startup script
ADD start.sh /start.sh
ADD znc.conf.default /znc.conf.default

# Change permissions on the default configuration
RUN chmod 0644 /znc.conf.default

# Volume for znc data and configuration files
VOLUME /opt/znc-data

# Expose the web port and IRC port
EXPOSE 8080 6697

# Add the startup script as an entrypoint
CMD []
ENTRYPOINT ["/start.sh"]
