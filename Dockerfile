ARG IMAGEM_BASE="doctorkirk/oracle-19c:latest"

FROM $IMAGEM_BASE

LABEL maintainer="Rodrigo Hiemer <rodrigo.hiemer@fabicads.com.br>"

USER root

RUN yum -y install rsync && \
    yum -y install gettext && \
    rm -rf /var/cache/yum/*

RUN mkdir /volumes && chmod -R 777 /volumes

USER oracle        

COPY src/sbin/ /usr/sbin/
RUN find /usr/sbin -type f  \ 
      -exec sh -c 'tr -d "\r" < "{}" > "{}".new && mv "{}".new "{}"' -- {} \; \    
      -exec chmod +x {} \;

ENV ORACLE_PWD "XK01JVKqO5c=1"

ENV FOLDER_ORACLE_SCRIPTS "/usr/sbin"

ENV ORACLE_SID "ORADOCKER"
ENV ORACLE_USER "SYS"
ENV ORACLE_USER_PASSWORD "oracle" 

ENV ORACLE_USER_SYSTEM "SYSTEM"
ENV ORACLE_USER_SYSTEM_PASSWORD "oracle"

ENV ORACLE_PDBADMIN_USER "PDBADMIN"
ENV ORACLE_PDBADMIN_PASSWORD "oracle"

ENV RELAX_SECURITY "true"
ENV ALLOW_REMOTE "true"

ENV NLS_LANG "BRAZILIAN PORTUGUESE_BRAZIL.UTF8"

ENV FOLDER_INIT_DB "/volumes/init/sql" 
ENV DIR_STARTUP_PIDS "/volumes/init/exec/pids"
ENV DIR_STARTUP_SQL "/volumes/init/exec/sqls"

ENV SQL_PLUS_CREDENTIALS_FILE "sql-plus-credentials"

ENV STARTUP_SYSTEM "true"
ENV FORCE_STARTUP_SYSTEM "false"

ENV FORCE_INIT "false"

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]
