################################################################################
# Dockerfile for appserver.io webserver Magento example
################################################################################

# base image
FROM debian:jessie

# author
MAINTAINER Tim Wagner <tw@appserver.io>

################################################################################

# define versions
ENV APPSERVER_RUNTIME_BUILD_VERSION 1.1.5-43

# update the sources list
RUN apt-get update \

    # install the necessary packages
    && DEBIAN_FRONTEND=noninteractive apt-get install supervisor wget git -y python-pip \

    # install the Python package to redirect the supervisord output
    && pip install supervisor-stdout

################################################################################

# download runtime in specific version
RUN wget -O /tmp/appserver-runtime.deb \
    http://builds.appserver.io/linux/debian/8/appserver-runtime_${APPSERVER_RUNTIME_BUILD_VERSION}~deb8_amd64.deb \

    # install runtime
    && dpkg -i /tmp/appserver-runtime.deb; exit 0

# install missing runtime dependencies
RUN apt-get install -yf \

    # remove the unnecessary .deb file
    && rm -f /tmp/appserver-runtime.deb \

    # create a symlink for the appserver.io PHP binary
    && ln -s /opt/appserver/bin/php /usr/local/bin/php

################################################################################

# install MySQL Server 5.6
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5 \
   && echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-5.6" >> /etc/apt/sources.list.d/dotdeb.list \
   && apt-get update \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

################################################################################

# install PHP 7 FPM
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/mysql.list \
   && echo "deb-src http://packages.dotdeb.org squeeze all" >> /etc/apt/sources.list.d/mysql.list \
   && wget https://www.dotdeb.org/dotdeb.gpg \
   && apt-key add dotdeb.gpg \
   && apt-get update \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes \
      php7.0-fpm \
      php7.0-curl \ 
      php7.0-mcrypt \
      php7.0-xml \
      php7.0-xsl \
      php7.0-intl \
      php7.0-mbstring \
      php7.0-zip \
      php7.0-gd \
      php7.0-mysql

################################################################################

# copy the appserver sources
ADD src /

################################################################################

# create the directory for the PHP-FPM .pid file
RUN mkdir /run/php

################################################################################

# define working directory
WORKDIR /var/www/magento

################################################################################

# copy Magento 2 sources
RUN tar xvfz Magento-CE-2.1.0.tar.gz \
   && cp -r /root/var/www/magento/* /var/www/magento \
   && ./composer.phar require appserver-io/webserver

################################################################################

# install Magento 2
RUN ./composer.phar install

################################################################################

# cleanup sources and private files
RUN rm /root/.composer/auth.json /var/www/magento/Magento-CE-2.1.0.tar.gz

################################################################################

# expose ports
EXPOSE 80

# supervisord needs this
CMD []

# define default command
ENTRYPOINT ["/usr/bin/supervisord"]
