# ============================================================
# Adding comment to trigger a build
# BASE Stage
FROM ubuntu:20.04 AS base

ARG ARCHIVESSPACE_VERSION="v3.3.1"
ARG ARCHIVESSPACE_USER_UID="40052"
ARG ARCHIVESSPACE_USER_GID="40052"
ARG DWO_PLUGIN_VERSION="v1.13"
ARG MYSQL_CONNECTOR_VERSION="8.0.23"

ENV ARCHIVESSPACE_LOGS="/dev/null"
ENV ARCHIVESSPACE_PLUGIN_DWO_URL="https://github.com/hudmol/digitization_work_order/archive/refs/tags/${DWO_PLUGIN_VERSION}.zip"
ENV ARCHIVESSPACE_SOURCE_URL="https://github.com/archivesspace/archivesspace/releases/download/${ARCHIVESSPACE_VERSION}/archivesspace-${ARCHIVESSPACE_VERSION}.zip"
ENV DEBIAN_FRONTEND="noninteractive"
ENV LANG="C.UTF-8"
ENV MYSQL_CONNECTOR_JAR_URL="https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar"
ENV TZ="UTC"

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      ca-certificates \
      git \
      netbase \
      openjdk-11-jre-headless \
      shared-mime-info \
      vim \
      wget \
      unzip && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g "$ARCHIVESSPACE_USER_GID" archivesspace && \
    useradd -M -u "$ARCHIVESSPACE_USER_UID" -g archivesspace archivesspace

# ============================================================
# Install ArchivesSpace
FROM base AS aspace
WORKDIR /opt
RUN wget -O aspace.zip "$ARCHIVESSPACE_SOURCE_URL" && \
    unzip aspace.zip && \
    mv archivesspace app && \
    chown -R archivesspace:archivesspace app && \
    rm -f aspace.zip

# Install MySQL Connector Java
RUN wget -O /opt/app/lib/$(basename "$MYSQL_CONNECTOR_JAR_URL") "$MYSQL_CONNECTOR_JAR_URL"

# ============================================================
# Install the Digitization Work Order plugin
FROM aspace AS digitization_work_order
WORKDIR /tmp
RUN wget -O digitization_work_order.zip "$ARCHIVESSPACE_PLUGIN_DWO_URL" && \
    unzip digitization_work_order.zip && \
    mv digitization_work_order-* /opt/app/plugins/digitization_work_order && \
    /opt/app/scripts/initialize-plugin.sh digitization_work_order && \
    rm -f digitization_work_order.zip

# ============================================================
# FINAL Stage
FROM base AS final

# Copy the built ArchivesSpace
COPY --from=aspace --chown=root:archivesspace /opt/app /opt/app

# Copy in our custom config files
COPY --chown=root:archivesspace files/config/config.rb /opt/app/config/config.rb
COPY --chown=root:archivesspace files/plugins/local/frontend/assets/images/* /opt/app/plugins/local/frontend/assets/images/
COPY --chown=root:archivesspace files/plugins/local/frontend/locales/en.rb /opt/app/plugins/local/frontend/locales/en.rb

# Copy the built DWO plugin
COPY --from=digitization_work_order --chown=root:archivesspace \
    /opt/app/plugins/digitization_work_order \
    /opt/app/plugins/digitization_work_order

# Install the entrypoint script.
COPY --chown=root:archivesspace docker-entrypoint.sh /bin/docker-entrypoint.sh
RUN chmod ug+x /bin/docker-entrypoint.sh
ENTRYPOINT ["/bin/docker-entrypoint.sh"]

USER archivesspace
WORKDIR /opt/app

# Note the `EXPOSE` is purely advisory. You can always map ports at runtime.
# @see https://archivesspace.github.io/tech-docs/customization/configuration.html
# staff interface
EXPOSE 8080
# public interface
EXPOSE 8081
# OAI-PMH server
EXPOSE 8082
# backend
EXPOSE 8089
# solr admin console
EXPOSE 8090

HEALTHCHECK --interval=1m --timeout=5s --start-period=5m --retries=2 \
  CMD wget -q --spider http://localhost:8089/ || exit 1
