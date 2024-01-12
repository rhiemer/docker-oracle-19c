ARG IMAGEM_BASE="doctorkirk/oracle-19c:latest"

FROM $IMAGEM_BASE

LABEL maintainer="Rodrigo Hiemer <rodrigo.hiemer@fabicads.com.br>"

USER root

RUN yum -y install rsync && \
    yum -y install gettext && \
    rm -rf /var/cache/yum/*

ARG USER_CONTAINER="oracle"
ARG GROUP_CONTAINER="dba"

ENV USER_CONTAINER="$USER_CONTAINER" \
    GROUP_CONTAINER="$GROUP_CONTAINER" \
    USER_CONTAINER_GROUP="${USER_CONTAINER_GROUP:-${USER_CONTAINER}:${GROUP_CONTAINER}}"

RUN mkdir -p /volumes && chmod -R 777 /volumes
RUN mkdir -p /init && chmod -R 777 /init 
RUN mkdir -p /data-pump && chmod -R 777 /data-pump 

ARG FOLDER_ORACLE_SCRIPTS_SOURCE="/src/scripts"
ARG FOLDER_ORACLE_SCRIPTS="/home/oracle/scripts"
ENV FOLDER_ORACLE_SCRIPTS_SOURCE="$FOLDER_ORACLE_SCRIPTS_SOURCE" \
    FOLDER_ORACLE_SCRIPTS="$FOLDER_ORACLE_SCRIPTS"    

RUN mkdir -p $FOLDER_ORACLE_SCRIPTS
COPY --chown=${USER_CONTAINER_GROUP} $FOLDER_ORACLE_SCRIPTS_SOURCE/ $FOLDER_ORACLE_SCRIPTS/
RUN chown -R $USER_CONTAINER_GROUP $FOLDER_ORACLE_SCRIPTS
RUN find $FOLDER_ORACLE_SCRIPTS -type f  \ 
      -exec sh -c 'tr -d "\r" < "{}" > "{}".new && mv "{}".new "{}"' -- {} \; \    
      -exec chmod +x {} \; \ 
      -exec chmod 777 {} \;

USER oracle        

ENV TZ "America/Sao_Paulo"
ENV BASH_ENV "/home/oracle/.bashrc"

ENV ORACLE_PWD "XK01JVKqO5c=1"
ENV ORACLE_SID "ORADOCKER"
ENV ORACLE_USER "SYS"
ENV ORACLE_USER_PASSWORD "oracle" 
ENV ORACLE_USER_SYSTEM "SYSTEM"
ENV ORACLE_USER_SYSTEM_PASSWORD "oracle"

ENV NLS_LANG "BRAZILIAN PORTUGUESE_BRAZIL.UTF8"

ENV FOLDER_INIT_DB "/volumes/init/sql"

ENV DIR_STARTUP_PIDS "/init/exec/pids"
ENV DIR_STARTUP_SQL "/init/exec/sqls"
ENV DIR_STARTUP_SQL_LOGS "/init/logs/sql"

ENV SQL_PLUS_CREDENTIALS_FILE "sql-plus-credentials"

ENV STARTUP_SYSTEM "true"
ENV RELAX_SECURITY "true"
ENV ALLOW_REMOTE "true"

ENV STARTUP_SQL_INIT "true"

ENV FORCE_INIT "false"

ENV ORACLE_ENABLE_XA_USER_DEFAULT "false"
ENV ORACLE_ENABLE_XA_ROLE_DEFAULT "true"
ENV ORACLE_ENABLE_ALL_TABLESPACES "false"

ENV ORACLE_USERS_PREFIX_ENVS "ORACLE_USER"
ENV ORACLE_ROLES_PREFIX_ENVS "ORACLE_ROLE"
ENV ORACLE_ROLES_PREFIX_TYPES_ENVS "ORACLE_ROLE_TYPE"
ENV ORACLE_DATAPUMP_RESTORE_PREFIX_ENVS "ORACLE_DATAPUMP_RESTORE"

ENV ORACLE_ROLE_USER_DBA_NAME "RL_USER_DBA"
ENV ORACLE_ROLE_USER_ADMIN_NAME "RL_USER_ADMIN"
ENV ORACLE_ROLE_USER_APP_NAME "RL_USER_APPLICATION"
ENV ORACLE_ROLE_USER_READONLY_NAME "RL_USER_READONLY"
ENV ORACLE_ROLE_SET_GRANTS_EXISTS "false"

ENV ORACLE_TABLE_SPACE_PREFIX_DEFAULT "TS"
ENV ORACLE_TABLE_SPACE_DEFAULT "USERS"
ENV ORACLE_TABLE_SPACE_PARAMS_DEFAULT "SIZE 10M AUTOEXTEND ON NEXT 5M"

ENV ORACLE_DATAPUMP_RESTORE_USER_CREATE "true"
ENV ORACLE_DATAPUMP_RESTORE_USER_RECREATE "true"
ENV ORACLE_DATAPUMP_RESTORE_ROLE_TYPE "ADMIN"
ENV ORACLE_DATAPUMP_RESTORE_TABLE_SPACE_CREATE "true"
ENV ORACLE_DATAPUMP_RESTORE_TABLE_SPACE_RECREATE "true"
ENV ORACLE_DATAPUMP_RESTORE_CREATE_DIRECTORY "true"
ENV ORACLE_DATAPUMP_RESTORE_LOG_FOLDER "/home/oracle/logs/imp"
ENV ORACLE_DATAPUMP_RESTORE_CREATE_DIRECTORY_LOG "true"

ENV ORACLE_DATAPUMP_RESTORE_TYPE "impdp"

ENV ORACLE_DATAPUMP_RESTORE_PARAMS_IMPDP "dumpfile=\$USER_DATAPUMP_RESTORE_FILE schemas=\$USER_DATAPUMP_RESTORE_TO directory=\$USER_DATAPUMP_RESTORE_TO logfile=\$FILE_LOG_DATAPUMP_RESTORE ignore=y"
ENV ORACLE_DATAPUMP_RESTORE_PARAMS_IMP "file=\$USER_DATAPUMP_RESTORE_FILE fromuser=\$USER_DATAPUMP_RESTORE_FROM touser=\$USER_DATAPUMP_RESTORE_TO grants=none commit=y ignore=y log=\$FILE_LOG_DATAPUMP_RESTORE"

ENTRYPOINT ["/home/oracle/scripts/entrypoint.sh"]
