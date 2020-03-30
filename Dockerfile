FROM openjdk:9-slim

LABEL maintainer="Steve Cliff <steve@devcloud.guru>"

ENV BASTILLION_VERSION=3.09.00 \
    BASTILLION_FILENAME=3.09_00 \
    DOCKERIZE_VERSION=0.6.1

RUN apt-get update && apt-get -y install wget && \
  wget --quiet https://github.com/bastillion-io/Bastillion/releases/download/v${BASTILLION_VERSION}/bastillion-jetty-v${BASTILLION_FILENAME}.tar.gz && \
  wget --quiet https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz && \
  tar xzf bastillion-jetty-v${BASTILLION_FILENAME}.tar.gz -C /opt && \
  tar xzf dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz -C /usr/local/bin && \
  mv /opt/Bastillion-jetty /opt/bastillion && \
  rm bastillion-jetty-v${BASTILLION_FILENAME}.tar.gz dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz && \
  apt-get remove --purge -y wget && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* && \
  # create db directory for later permission update
  mkdir /opt/bastillion/jetty/bastillion/WEB-INF/classes/keydb && \
  # remove default config - will be written by dockerize on startup
  rm /opt/bastillion/jetty/bastillion/WEB-INF/classes/BastillionConfig.properties

# persistent data of Bastillion is stored here
VOLUME /opt/bastillion/jetty/bastillion/WEB-INF/classes/keydb

# this is the home of Bastillion
WORKDIR /opt/bastillion

# Bastillion listens on 8443 - HTTPS, 8080 - HTTP
EXPOSE 8080 8443

# Bastillion configuration template for dockerize
ADD files/BastillionConfig.properties.tpl /opt

# Configure Jetty
ADD files/jetty-start.ini /opt/bastillion/jetty/start.ini

# Custom Jetty start script
ADD files/startBastillion.sh /opt/bastillion/startBastillion.sh

# correct permission for running as non-root (f.e. on OpenShift)
RUN chmod 755 /opt/bastillion/startBastillion.sh && \
    chgrp -R 0 /opt/bastillion && \
    chmod -R g=u /opt/bastillion

# dont run as root
USER 1001

ENTRYPOINT ["/usr/local/bin/dockerize"]
CMD ["-template", \
     "/opt/BastillionConfig.properties.tpl:/opt/bastillion/jetty/bastillion/WEB-INF/classes/BastillionConfig.properties", \
     "/opt/bastillion/startBastillion.sh"]
