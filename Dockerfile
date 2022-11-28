FROM ubuntu:20.04 as build_release

# Please note: Docker is not supported as an install method.
# Docker configuration is being used for internal purposes only.
# Use of Docker by anyone else is "use at your own risk".
# Docker related files may be updated at anytime without
# warning or presence in release notes.

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC

ARG ASPACE_VERSION='v3.3.1'

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      build-essential \
      git \
      openjdk-11-jre-headless \
      shared-mime-info \
      wget \
      unzip

COPY . /source

RUN cd /source && \
    wget https://github.com/archivesspace/archivesspace/releases/download/$ASPACE_VERSION/archivesspace-$ASPACE_VERSION.zip && \
    mv ./*.zip / && \
    cd / && \
    unzip /*.zip -d / && \
    #mv /source/config.rb /archivesspace/config/config.rb && \
    wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar && \
    cp ./mysql-connector-java-8.0.23.jar /archivesspace/lib/ && \ 
    wget -c https://github.com/hudmol/digitization_work_order/archive/refs/tags/v1.13.zip -O dig-v1.13.zip && \ 
    unzip ./dig-v1.13.zip -d /archivesspace/plugins/ && \
    wget -c https://github.com/quoideneuf/aspace_oclc/releases/download/0.0.2/oclc.zip -O oclc.zip && \
    unzip ./oclc.zip -d /archivesspace/plugins/oclc/ 
    

FROM ubuntu:20.04

LABEL maintainer="ArchivesSpaceHome@lyrasis.org"

ENV ARCHIVESSPACE_LOGS=/dev/null \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC

COPY --from=build_release /archivesspace /archivesspace

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      ca-certificates \
      git \
      openjdk-11-jre-headless \
      netbase \
      shared-mime-info \
      vim \
      wget \
      unzip && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 1000 archivesspace && \
    useradd -l -M -u 1000 -g archivesspace archivesspace && \
    chown -R archivesspace:archivesspace /archivesspace

EXPOSE 8080 8081 8089 8090 8092

HEALTHCHECK --interval=1m --timeout=5s --start-period=5m --retries=2 \
  CMD wget -q --spider http://localhost:8089/ || exit 1

USER archivesspace 
CMD /archivesspace/archivesspace.sh
