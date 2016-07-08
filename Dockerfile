################################################################################
# Dockerfile for appserver.io webserver Magento 2 example
################################################################################

# base image
FROM debian:jessie

# author
MAINTAINER Tim Wagner <tw@appserver.io>

################################################################################

# Magent 2 specific configuration data
ARG COMPOSER_OAUTH_GITHUB=<YOUR-GITHUB-OAUTH-TOKEN>
ARG COMPOSER_REPO_USER=<YOUR-USERNAME>
ARG COMPOSER_REPO_PASSWORD=<YOUR-PASSWORD>

# define versions
ARG MAGENTO_VERSION=2.1.0
ARG MAGENTO_PACKAGE=magento/project-community-edition
ARG MAGENTO_REPOSITORY=https://repo.magento.com/
ARG APPSERVER_RUNTIME_BUILD_VERSION=1.1.5-43

################################################################################

# update the sources list
RUN apt-get update \

    # install the necessary packages
    && DEBIAN_FRONTEND=noninteractive apt-get install supervisor wget git curl -y python-pip \

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
   && echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/mysql.list \
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

# create the directory for the PHP-FPM .pid file and the working directory
RUN mkdir /run/php && mkdir /var/www

################################################################################

# clear apk cache to optimize image filesize
RUN rm -rf /var/cache/apk/*

################################################################################

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

################################################################################

# install Magento 2 sources, configure authentication and override sources
RUN sed -i 's/{{COMPOSER_REPO_USER}}/'"$COMPOSER_REPO_USER"'/g' /root/.composer/auth.json \
   && sed -i 's/{{COMPOSER_REPO_PASSWORD}}/'"$COMPOSER_REPO_PASSWORD"'/g' /root/.composer/auth.json \
   && sed -i 's/{{COMPOSER_OAUTH_GITHUB}}/'"$COMPOSER_OAUTH_GITHUB"'/g' /root/.composer/auth.json \
   && composer create-project --repository-url=$MAGENTO_REPOSITORY $MAGENTO_PACKAGE=$MAGENTO_VERSION /var/www/magento \
   && cp -r /root/var/www/magento/* /var/www/magento

################################################################################

# define working directory
WORKDIR /var/www/magento

################################################################################

# install the appserver.io webserver
RUN composer require appserver-io/webserver && composer install

################################################################################

# expose ports
EXPOSE 80

# supervisord needs this
CMD []

# define default command
ENTRYPOINT ["/usr/bin/supervisord"]
