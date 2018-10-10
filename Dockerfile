FROM openjdk:8u171-jre-alpine3.8
MAINTAINER Wang Liang <wangl8@knownsec.com>
 
# Install required packages
RUN apk add --no-cache  \
    bash \
    su-exec 
 
ENV ZOO_USER=zookeeper \
    ZOO_CONF_DIR=/conf \
    ZOO_DATA_DIR=/data \
    ZOO_UI_DIR=/zkui \
    ZOO_DATA_LOG_DIR=/datalog \
    ZOO_PORT=2181 \
    ZOO_TICK_TIME=2000 \
    ZOO_INIT_LIMIT=5 \
    ZOO_SYNC_LIMIT=2
 
# Add a user and make dirs
RUN set -ex \
    && adduser -D "$ZOO_USER" \
    && mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_UI_DIR" \
    && chown "$ZOO_USER:$ZOO_USER" "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR"
 
ARG GPG_KEY=586EFEF859AF2DB190D84080BDB2011E173C31A2
ARG DISTRO_NAME=zookeeper-3.4.12
COPY keygpg .
 
# Download Apache Zookeeper, verify its PGP signature, untar and clean up
RUN set -x \
    && apk add --no-cache --virtual .build-deps \
        gnupg \
        net-tools \
    && wget -q "http://www.apache.org/dist/zookeeper/$DISTRO_NAME/$DISTRO_NAME.tar.gz" \
    && wget -q "http://www.apache.org/dist/zookeeper/$DISTRO_NAME/$DISTRO_NAME.tar.gz.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
 #   && wget -q  https://apache.org/dist/zookeeper/KEYS \
 #   && gpg --import KEYS  \
 #   && gpg --list-keys \
  #  && gpg  --keyserver  http://pgp.mit.edu  --recv-key "$GPG_KEY" \
  #  && ping pgp.mit.edu \
 #   && gpg --batch --verify "$DISTRO_NAME.tar.gz.asc" "$DISTRO_NAME.tar.gz" \
    && tar -xzf "$DISTRO_NAME.tar.gz" \
    && mv "$DISTRO_NAME/conf/"* "$ZOO_CONF_DIR" \
    && rm -r "$GNUPGHOME" "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc" \
    && apk del .build-deps
 
ADD zkui-2.0-SNAPSHOT-jar-with-dependencies.jar $ZOO_UI_DIR/
ADD config.cfg $ZOO_UI_DIR/
WORKDIR /$DISTRO_NAME
VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR"]
 
EXPOSE $ZOO_PORT 2888 3888
 
ENV PATH=$PATH:/$DISTRO_NAME/bin:$ZOO_UI_DIR \
    ZOOCFGDIR=$ZOO_CONF_DIR
COPY docker-entrypoint.sh /
WORKDIR /
#CMD ["sh","-c","docker-entrypoint.sh"]
ENTRYPOINT ["./docker-entrypoint.sh"]
