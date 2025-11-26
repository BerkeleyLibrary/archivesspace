FROM solr:9

ARG ARCHIVESSPACE_VERSION="v4.1.1"
ENV ARCHIVESSPACE_SOURCE_URL="https://github.com/archivesspace/archivesspace/releases/download/${ARCHIVESSPACE_VERSION}/archivesspace-${ARCHIVESSPACE_VERSION}.zip"

# Upgrade system packages and install wget
USER root
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
      unzip \
      wget && \
    rm -rf /var/lib/apt/lists/*

# Create a configset for the given ASpace release
RUN mkdir -p /opt/solr/server/solr/configsets/archivesspace/conf && \
    wget -O aspace.zip "$ARCHIVESSPACE_SOURCE_URL" && \
    unzip aspace.zip 'archivesspace/solr/*' && \
    mv archivesspace/solr/* /opt/solr/server/solr/configsets/archivesspace/conf/ && \
    rm -rf aspace.zip archivesspace
USER solr
