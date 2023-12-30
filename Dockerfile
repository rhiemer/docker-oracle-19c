ARG IMAGEM_BASE="doctorkirk/oracle-19c:latest"

FROM $IMAGEM_BASE

LABEL maintainer="Rodrigo Hiemer <rodrigo.hiemer@fabicads.com.br>"

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt-get update \
    && apt-get install -y \
       rsync \
       gettext-base
 
ARG ORACLE_HOME="/u01/app/oracle/product/11.2.0/xe"
ARG ORACLE_SID="XE"
ARG ORACLE_DATA="/u01/app/oracle/oradata"
ARG ORACLE_LIBS="/u01/app/oracle/product/11.2.0/xe/lib"
ARG ORACLE_USER="SYS"
ARG ORACLE_USER_PASSWORD="oracle" 
ARG ORACLE_USER_SYSTEM="SYSTEM"
ARG ORACLE_USER_SYSTEM_PASSWORD="oracle"

ENV ORACLE_HOME="$ORACLE_HOME" \
    ORACLE_LIBS="$ORACLE_LIBS" \
    ORACLE_SID="$ORACLE_SID" \
    ORACLE_DATA="$ORACLE_DATA/$ORACLE_SID" \
    ORACLE_USER="$ORACLE_USER" \
    ORACLE_USER_PASSWORD="$ORACLE_USER_PASSWORD" \
    ORACLE_USER_SYSTEM="$ORACLE_USER_SYSTEM" \
    ORACLE_USER_SYSTEM_PASSWORD="$ORACLE_USER_SYSTEM_PASSWORD" \
    LD_LIBRARY_PATH="${ORACLE_LIBS}:${PATH}" \    
    PATH="${ORACLE_HOME}/bin:${PATH}"

COPY assets /assets
COPY src/setup/ /
RUN /setup.sh

COPY src/sbin/ /usr/sbin/
RUN find /usr/sbin/init.sh -type f  \ 
      -exec sh -c 'tr -d "\r" < "{}" > "{}".new && mv "{}".new "{}"' -- {} \; \    
      -exec chmod +x {} \;

ENV NLS_LANG "BRAZILIAN PORTUGUESE_BRAZIL.UTF8"

ENV FOLDER_INIT_DB "/docker-entrypoint-initdb.d" 
ENV SQL_PLUS_CREDENTIALS_FILE "sql-plus-credentials"
ENV ORACLE_ALLOW_REMOTE "true"
ENV ORACLE_RELAX_SECURITY "1"
ENV ORACLE_PASSWORD "oracle"
ENV ORACLE_FORCE_STARTUP_SYSTEM "true"
ENV ORACLE_FORCE_INIT "false"
ENV ORACLE_FORCE_SET_PROCESS "false"
ENV ORACLE_RESTART_FILE "/usr/sbin/restart-oracle"


ENTRYPOINT ["/usr/sbin/entrypoint.sh"]
