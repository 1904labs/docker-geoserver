FROM openjdk:8-jdk-slim-buster

# Build Args
ARG BUILD_DATE=None
ARG VCS_REF=None
ARG BUILD_VERSION=None

# Labels.
LABEL maintainer="gjunge@1904labs.com" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="1904labs/geoserver" \
      org.label-schema.description="1904labs Geoserver image" \
      org.label-schema.url="https://1904labs.com/" \
      org.label-schema.vcs-url="https://github.com/1904labs/docker-geoserver" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vendor="1904labs" \
      org.label-schema.version=${BUILD_VERSION} \
      org.label-schema.docker.cmd="docker run -p 8080:8080 -d 1904labs/geoserver"

ARG TOMCAT_VERSION=9.0.36
ARG GEOSERVER_VERSION=2.17.1

RUN set -ex && \
    sed -i 's/main$/main contrib/' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y curl msttcorefonts libfreetype6 fontconfig unzip && \
    rm -rf /var/cache/apt/*

WORKDIR /tmp

# Install tomcat
RUN set -ex && \
  mkdir -p /opt/tomcat && \
  curl -sSLO https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
  tar -xzvf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat --strip-components=1 && \
  rm apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Install geoserver
RUN set -ex && \
  mkdir -p /opt/tomcat/webapps/geoserver && \
  curl -sSLO  https://downloads.sourceforge.net/project/geoserver/GeoServer/${GEOSERVER_VERSION}/geoserver-${GEOSERVER_VERSION}-war.zip && \
  unzip geoserver-${GEOSERVER_VERSION}-war.zip geoserver.war && \
  unzip -o geoserver.war -d /opt/tomcat/webapps/geoserver && \
  rm -r /opt/tomcat/webapps/geoserver/META-INF

# Install geoserver WPS plugin
RUN set -ex && \
  curl -sSLO https://downloads.sourceforge.net/project/geoserver/GeoServer/${GEOSERVER_VERSION}/extensions/geoserver-${GEOSERVER_VERSION}-wps-plugin.zip && \
  unzip -jo geoserver-${GEOSERVER_VERSION}-wps-plugin.zip -d /opt/tomcat/webapps/geoserver/WEB-INF/lib/ 

# create tomcat user
RUN set -x && \
   groupadd tomcat && \
   useradd -s /bin/nologin -g tomcat -Md /opt/tomcat tomcat && \
   chown -R tomcat:tomcat /opt/tomcat

# clenaup
RUN rm -rf /tmp/* 

USER tomcat
WORKDIR /opt/tomcat/webapps/geoserver
EXPOSE 8080
ENV CATALINA_OPTS "-Xmx8g -XX:MaxPermSize=512M -Duser.timezone=UTC -server -Djava.awt.headless=true"
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
