ARG BEDROCK_SERVER_VER=1.12.1.1

FROM busybox:latest as unzip
ARG BEDROCK_SERVER_DIR=downloads
ARG BEDROCK_SERVER_VER
COPY ${BEDROCK_SERVER_DIR}/bedrock-server-${BEDROCK_SERVER_VER}.zip .
RUN mkdir -pv /usr/local/src/bedrock && unzip bedrock-server-$BEDROCK_SERVER_VER.zip -d /usr/local/src/bedrock


FROM ubuntu:18.04
ENV LD_LIBRARY_PATH=/opt/bedrock
RUN apt-get update && apt-get install -y \
  libcurl4
WORKDIR /opt/bedrock
COPY --from=unzip /usr/local/src/bedrock /opt/bedrock
ARG BEDROCK_SERVER_VER
RUN echo $BEDROCK_SERVER_VER > bedrock_server_version
COPY ./entrypoint.sh ./
EXPOSE 19132/udp
VOLUME ["/volume"]
ENTRYPOINT ["/bin/bash", "./entrypoint.sh"]
