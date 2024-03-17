ARG PHP_VERSION
ARG DEBIAN_VERSION
FROM php:${PHP_VERSION}-${DEBIAN_VERSION}
ARG XDEBUG_VERSION
SHELL ["/bin/bash", "-c"]
ARG COMPOSER_HOME=/composer
ENV NPM_ENTRYPOINT=/usr/local/bin/docker-npm-entrypoint
ENV YARN_ENTRYPOINT=/usr/local/bin/docker-yarn-entrypoint
ENV ACCEPT_EULA="Y"
RUN a2enmod rewrite expires include deflate

WORKDIR /var/www/

ENV APACHE_RUN_USER www-data
ENV APACHE_DOCUMENT_ROOT /var/www/public
ENV APACHE_PORT 80
RUN usermod -u 1000 www-data;

# terminal colors with xterm
ENV TERM xterm

# phars directory
ENV PHARS_DIR /opt/phars
RUN mkdir -p $PHARS_DIR
ENV PATH $PHARS_DIR:$PATH

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN sed -ri -e 's!<VirtualHost \*:80>!<VirtualHost *:${APACHE_PORT}>!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!<VirtualHost _default_:443>!<VirtualHost _default_:${APACHE_PORT}>!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!Listen 80!Listen ${APACHE_PORT}!g' /etc/apache2/ports.conf

# Installation de modules PHP
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-utils \
        bc \
        zsh \
    	libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libpq-dev \
        libldap2-dev \
        libldb-dev \
        libicu-dev \
        libbz2-dev \
        libgmp-dev \
        libmagickwand-dev \
        libc-client-dev \
        libtidy-dev \
        libkrb5-dev \
        libxslt-dev \
        unixodbc-dev \
        openssh-server \
        vim \
        curl \
        wget \
        tcptraceroute \
        libcurl4 \
        libcurl4-openssl-dev \
        zip \
        unzip \
        zlib1g-dev \
        libzip-dev \
        mariadb-client \
        pngquant \
        libmcrypt-dev \
        git \
        libxml2-dev \
        libssl-dev \
        libsqlite3-dev  \
        libsqlite3-0 \
        libzip4\
        telnet \
        iputils-ping \
        mlocate \
        wkhtmltopdf \
        locales-all \
        libreadline-dev \
        libfreetype6-dev \
        autoconf \
        automake \
        bash \
        postgresql-client \
        libwebp-dev \
        libonig-dev \
        chromium  \
        gnupg2 \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h


RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt-get update && apt-get -y install google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-khmeros fonts-kacst fonts-freefont-ttf libxss1 dbus dbus-x11

# Installation de composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Installation du php.ini
COPY php.ini /usr/local/etc/php/conf.d/app.ini

RUN docker-php-ext-install mysqli bcmath intl xml pdo_mysql pgsql pdo_pgsql pdo_sqlite zip dom session opcache curl bz2 iconv calendar exif xsl mbstring \
    && pecl install apcu && docker-php-ext-enable apcu \
    && pecl install imagick && docker-php-ext-enable  imagick

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
        && docker-php-ext-install gd

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions http

#RUN   mkdir -p /usr/local/nvm && \
#      curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash && \
#      source ~/.bashrc && \
#      nvm install --lts
#
#RUN    npm install -g npm && \
#      npm install gulp bower -g && \
#      npm install --global yarn && \
#      npm install -g @vue/cli

RUN pecl install xdebug-${XDEBUG_VERSION} && docker-php-ext-enable  xdebug;

## Quality tools
RUN composer global require phing/phing
RUN composer global require phploc/phploc
RUN composer global require phpmd/phpmd
RUN composer global require squizlabs/php_codesniffer
RUN composer global require pear/archive_tar
RUN composer global require friendsofphp/php-cs-fixer --with-all-dependencies
RUN #composer global require codeception/codeception
RUN wget -O /usr/local/bin/local-php-security-checker https://github.com/fabpot/local-php-security-checker/releases/download/v2.0.6/local-php-security-checker_2.0.6_linux_386
#RUN chmod +x /usr/local/bin/local-php-security-checker
RUN composer global require phpmetrics/phpmetrics
RUN composer global require phpstan/phpstan
RUN composer global require vimeo/psalm
RUN curl -L http://phpdoc.org/phpDocumentor.phar -o $PHARS_DIR/phpDocumentor
RUN chmod +x $PHARS_DIR/phpDocumentor


### exemple d'utilisation du node yarn/npm dans un docker-compose
#  yarn:
#    image: 'devpartitech/php:8.1-apache'
#    ports:
#      - "9081:80"
#    entrypoint: /usr/local/bin/node-yarn-entrypoint
#    volumes:
#      - "./www/:/var/www/public"
#    extra_hosts:
#      - host.docker.internal:host-gateway

# entrypoint for npm.
#RUN touch ${NPM_ENTRYPOINT}
#RUN echo "#!/bin/sh" > ${NPM_ENTRYPOINT}
#RUN echo "npm install && npm run serve" >> ${NPM_ENTRYPOINT}
#RUN chmod +x ${NPM_ENTRYPOINT}
#
### entrypoint for yarn.
#RUN touch ${YARN_ENTRYPOINT}
#RUN echo "#!/bin/sh" > ${YARN_ENTRYPOINT}
#RUN echo "yarn install && yarn watch" >> ${YARN_ENTRYPOINT}
#RUN chmod +x ${YARN_ENTRYPOINT}

RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash && \
    apt install symfony-cli

# the user we're applying this too (otherwise it most likely install for root)
USER $USER_NAME
# terminal colors with xterm
ENV TERM xterm
# set the zsh theme
ENV ZSH_THEME agnoster
# install powerline fonts for most of zh themes.
RUN cd /tmp/ && git clone https://github.com/powerline/fonts.git \
    && cd fonts && ./install.sh \
    && cd /tmp && rm -Rf /tmp/fonts

RUN apt-get -y install ruby && gem install bundler && gem install capistrano


RUN usermod -u 1000 www-data
RUN usermod -G staff www-data