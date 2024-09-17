# ============================================================
# Adding comment to trigger a build
# BASE Stage
FROM ubuntu:20.04 AS base

ARG ARCHIVESSPACE_USER_GID="40052"
ARG ARCHIVESSPACE_USER_UID="40052"
ARG ARCHIVESSPACE_VERSION="v3.3.1"
ARG DWO_PLUGIN_VERSION="v1.13"
ARG MT_PLUGIN_VERSION="v1.5"
ARG MYSQL_CONNECTOR_VERSION="8.0.23"
ARG TIMEWALK_PLUGIN_VERSION="3.0"

ENV ARCHIVESSPACE_LOGS="/dev/null"
ENV ARCHIVESSPACE_PLUGIN_DWO_URL="https://github.com/hudmol/digitization_work_order/archive/refs/tags/${DWO_PLUGIN_VERSION}.zip"
ENV ARCHIVESSPACE_PLUGIN_MT_URL="https://github.com/hudmol/material_types/archive/refs/tags/${MT_PLUGIN_VERSION}.zip"
ENV ARCHIVESSPACE_PLUGIN_TIMEWALK_URL="https://github.com/alexduryee/timewalk/archive/refs/tags/${TIMEWALK_PLUGIN_VERSION}.zip"
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
    useradd -m -u "$ARCHIVESSPACE_USER_UID" -g archivesspace archivesspace

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
# Install the Timewalk plugin
FROM aspace AS timewalk
WORKDIR /tmp
RUN wget -O timewalk.zip "$ARCHIVESSPACE_PLUGIN_TIMEWALK_URL" && \
    unzip timewalk.zip && \
    mv timewalk-* /opt/app/plugins/timewalk && \
    /opt/app/scripts/initialize-plugin.sh timewalk && \
    rm -f timewalk.zip

# ============================================================
# Install the Material Types plugin
FROM aspace AS material_types
WORKDIR /tmp
RUN wget -O material_types.zip "$ARCHIVESSPACE_PLUGIN_MT_URL" && \
    unzip material_types.zip && \
    mv material_types-* /opt/app/plugins/material_types && \
    rm -f material_types.zip

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

# Copy the built Materials Type plugin
COPY --from=material_types --chown=root:archivesspace \
    /opt/app/plugins/material_types \
    /opt/app/plugins/material_types

# Copy the built Timewalk plugin
COPY --from=timewalk --chown=root:archivesspace \
    /opt/app/plugins/timewalk \
    /opt/app/plugins/timewalk

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
