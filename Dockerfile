FROM oracle/database:18.4.0-xe

MAINTAINER Raphael Hinterndorfer <dev@rammelhof.at>

# environment variables
ENV INSTALL_APEX=true \
    INSTALL_SQLCL=true \
    INSTALL_SQLDEVWEB=true \
    INSTALL_LOGGER=true \
    INSTALL_OOSUTILS=true \
    INSTALL_AOP=false \
    INSTALL_AME=false \
    INSTALL_SWAGGER=true \
    INSTALL_CA_CERTS_WALLET=true \
    DBCA_TOTAL_MEMORY=2048 \
    ORACLE_SID=XE \
    SERVICE_NAME=XE \
    ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE \
    PASS=oracle \
    ORACLE_PWD=oracle \
    ORDS_HOME=/opt/ords \
    JAVA_HOME=/opt/java \
    TOMCAT_HOME=/opt/tomcat \
    APEX_PASS=OrclAPEX1999! \
    APEX_ADDITIONAL_LANG=de \
    TIME_ZONE=UTC

# copy all scripts
ADD scripts /scripts/

# copy all files
ADD files /files/

# image setup via shell script to reduce layers and optimize final disk usage
RUN /scripts/install_main.sh

# ssh, database and apex port
EXPOSE 22 1521 8080

# use ${ORACLE_BASE} without product subdirectory as data volume
VOLUME ["${ORACLE_BASE}"]

# entrypoint for database creation, startup and graceful shutdown
ENTRYPOINT ["/scripts/entrypoint.sh"]
