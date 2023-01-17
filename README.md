# Docker Templates

We are using theses images for quick dev setup. Do not use it on production servers, they have not been made for. If you need a quick image for dev purpose you can either get what you need from this repo or directly get images from our docker.io repo : https://hub.docker.com/r/devpartitech/php/tags



Connect to Docker.io

```
docker login -u MyTeam -p MyPass
```

You will need to activate the experimental mode
Create the daemon.json file

```
vi /etc/docker/daemon.json
```

```
{
"experimental": true
}
```

```
sudo service docker restart
```

To generate images build you will need to execute the build.sh file. Check the script and update it as you need.

All image in this repository have been pushed to : 

https://hub.docker.com/r/devpartitech/php/tags



Here is an example on how you could use images in your docker-compose file.

```
version: "3.8"
services:
  php-8.1:
    image: 'devpartitech/php:8.1-apache'
    ports:
      - "9081:80"
    volumes:
      - "./www/:/var/www/public"
    extra_hosts:
      - host.docker.internal:host-gateway
  php-8.0:
    image: 'devpartitech/php:8.0-apache'
    ports:
      - "9080:80"
    volumes:
      - "./www/:/var/www/public"
    extra_hosts:
      - host.docker.internal:host-gateway
  php-7.4:
    image: 'devpartitech/php:7.4-apache'
    ports:
      - "9074:80"
    volumes:
      - "./www/:/var/www/public"
    extra_hosts:
      - host.docker.internal:host-gateway
  php-7.3:
    image: 'devpartitech/php:7.3-apache'
    ports:
      - "9073:80"
    volumes:
      - "./www/:/var/www/public"
    extra_hosts:
      - host.docker.internal:host-gateway
  php-7.2:
    image: 'devpartitech/php:7.2-apache'
    ports:
      - "9072:80"
    volumes:
      - "./www/:/var/www/public"
    extra_hosts:
      - host.docker.internal:host-gateway
```



** FYI: mssql client haven't been built on the php 8.0 and 8.1. 
