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
        gearman-tools libgearman-dev gearman gearman-job-server \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h


# Installation de composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Installation du php.ini
COPY php.ini /usr/local/etc/php/conf.d/app.ini

# Install the Microsoft SQL Server PDO driver on supported versions only.
#  - https://docs.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac
#  - https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server
RUN set -eux; \
    if [[ $PHP_VERSION == 7.1.* || $PHP_VERSION == 7.2.* || $PHP_VERSION == 7.3.* ]]; then \
        apt-get update && apt-get install -y gnupg2 apt-transport-https && \
        curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -; \
        curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list; \
        apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev mssql-tools18; \
		pecl install sqlsrv-5.8.1 pdo_sqlsrv-5.8.1 && \
		echo extension=pdo_sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini && \
		echo extension=sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/20-sqlsrv.ini; \
	fi
RUN set -eux; \
    if [[ $PHP_VERSION == 7.4.* ]]; then \
        dpkg --add-architecture i386 && apt-get update && \
        apt-get install -y gnupg2 apt-transport-https && \
        curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
        curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
        apt-get update && \
        apt-get install -y msodbcsql18 mssql-tools18 unixodbc-dev libgssapi-krb5-2 pip libunwind8 tar python && \
        update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
        pecl install sqlsrv pdo_sqlsrv && \
        docker-php-ext-enable sqlsrv pdo_sqlsrv && \
        echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile && \
        echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc && \
        curl -SL https://github.com/microsoft/sqltoolsservice/releases/download/v3.0.0-release.205/Microsoft.SqlTools.ServiceLayer-rhel-x64-net6.0.tar.gz -o /tmp/Microsoft.SqlTools.ServiceLayer.tar.gz && \
        mkdir /tmp/Microsoft.SqlTools.ServiceLayer && \
        tar -xzf /tmp/Microsoft.SqlTools.ServiceLayer.tar.gz -C /tmp/Microsoft.SqlTools.ServiceLayer && \
        mv /tmp/Microsoft.SqlTools.ServiceLayer /opt/Microsoft.SqlTools.ServiceLayer && \
        pip install mssql-scripter && \
        rm -rf /var/lib/apt/lists/*;\
    fi

ENV MSSQLTOOLSSERVICE_PATH=/opt/Microsoft.SqlTools.ServiceLayer

RUN set -x \
    && docker-php-source extract \
    && cd /usr/src/php/ext/odbc \
    && phpize \
    && sed -ri 's@^ *test +"\$PHP_.*" *= *"no" *&& *PHP_.*=yes *$@#&@g' configure \
    && ./configure --with-unixODBC=shared,/usr \
    && docker-php-ext-install mysqli bcmath intl xml pdo_mysql pgsql pdo_pgsql pdo_sqlite zip dom session opcache curl bz2 iconv calendar exif xsl mbstring \
    && pecl install apcu && docker-php-ext-enable apcu \
    && pecl install imagick && docker-php-ext-enable  imagick


RUN set -eux; \
    if [[ $PHP_VERSION == 7.1.* || $PHP_VERSION == 7.2.* || $PHP_VERSION == 7.3.* ]]; then \
      docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd; \
    fi

RUN set -eux; \
    if [[ $PHP_VERSION == 7.4.*  || $PHP_VERSION == 8.0.* || $PHP_VERSION == 8.1.* || $PHP_VERSION == 8.2.*  ]]; then \
      docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
        && docker-php-ext-install gd; \
    fi



RUN set -eux; \
    if [[ $PHP_VERSION == 7.1.* || $PHP_VERSION == 7.2.* || $PHP_VERSION == 7.3.*  || $PHP_VERSION == 7.4.* ]]; then \
        git clone -b master https://github.com/wcgallego/pecl-gearman.git /tmp/php-gearman/ \
        	&& cd /tmp/php-gearman/ \
        	&& phpize \
        	&& ./configure \
        	&& make \
        	&& make install \
        	&& docker-php-ext-enable gearman; \
	fi

RUN set -eux; \
    if [[ $PHP_VERSION == 8.0.* || $PHP_VERSION == 8.1.* || $PHP_VERSION == 8.2.*  ]]; then \
        git clone -b master https://github.com/php/pecl-networking-gearman.git /tmp/php-gearman/ \
        	&& cd /tmp/php-gearman/ \
        	&& phpize \
        	&& ./configure \
        	&& make \
        	&& make install \
        	&& docker-php-ext-enable gearman; \
	fi

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && \
    sync && \
    install-php-extensions http


ENV NVM_DIR=/usr/local/nvm
RUN   mkdir -p $NVM_DIR && \
      curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash && \
      source $NVM_DIR/nvm.sh &&\
      nvm install 13 && \
      nvm install 14 && \
      nvm install 15 && \
      nvm install 16 && \
      nvm install 17 && \
      nvm install 18 && \
      nvm install 19 && \
      nvm alias default 19 && \
      nvm use default && \
      npm install -g npm@9.1.2 && \
      npm install gulp bower -g && \
      npm install --global yarn && \
      npm install -g @vue/cli

RUN pecl install xdebug-${XDEBUG_VERSION} && docker-php-ext-enable  xdebug;

# Quality tools
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
RUN touch ${NPM_ENTRYPOINT}
RUN echo "#!/bin/sh" > ${NPM_ENTRYPOINT}
RUN echo "npm install && npm run serve" >> ${NPM_ENTRYPOINT}
RUN chmod +x ${NPM_ENTRYPOINT}

## entrypoint for yarn.
RUN touch ${YARN_ENTRYPOINT}
RUN echo "#!/bin/sh" > ${YARN_ENTRYPOINT}
RUN echo "yarn install && yarn watch" >> ${YARN_ENTRYPOINT}
RUN chmod +x ${YARN_ENTRYPOINT}

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

# inatall a viual theme.
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.2/zsh-in-docker.sh)" -- \
#    -t https://github.com/denysdovhan/spaceship-prompt \
    -a 'SPACESHIP_PROMPT_ADD_NEWLINE="false"' \
    -a 'SPACESHIP_PROMPT_SEPARATE_LINE="false"' \
    -p git \
    -p ssh-agent \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    && mkdir /root/.ssh

RUN usermod -u 1000 www-data
RUN usermod -G staff www-data