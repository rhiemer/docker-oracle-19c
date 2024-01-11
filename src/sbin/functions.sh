
COMMAND_SQL=()
COMMAND_SQL+=($FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} -f )

PYTHON_CMD="${PYTHON_CMD:-python}"
ORACLE_CREDENTIALS="${ORACLE_CREDENTIALS:-$SQL_PLUS_CREDENCIAIS_ADMIN}"
_USER_CREDENTIAL="$( echo $ORACLE_CREDENTIALS |  awk -F '/' '{print $1}' )"

createDirectoryOracle(){

  P_DIRECTORY="${1}"
  P_DIRECTORY_PATH="${2}"
  P_USER="${3}"

  echo "Criando diretório no oracle $P_DIRECTORY - $P_DIRECTORY_PATH. Permissões para o usuário $P_USER"

  mkdir -pv "$P_DIRECTORY_PATH"
  echo "CREATE OR REPLACE DIRECTORY $P_DIRECTORY AS '$P_DIRECTORY_PATH';" | ${COMMAND_SQL[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
  echo "GRANT READ, WRITE ON DIRECTORY $P_DIRECTORY TO $P_USER;" | ${COMMAND_SQL[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
  
}

createDirectoryOracleAuth(){

  P_PREFIX="${1}"
  P_DIRECTORY_PATH="${2}"
  P_USER="${3}"

  _DIRECTORY=`${PYTHON_CMD[@]} -c "import uuid;print(uuid.uuid1())"`
  _DIRECTORY="${_DIRECTORY%%-*}"
  _DIRECTORY="${_DIRECTORY^^}"
  _DIRECTORY="${P_PREFIX}_${_DIRECTORY}"

  createDirectoryOracle "$_DIRECTORY" "$P_DIRECTORY_PATH" "$P_USER"
}

enableUserXAOracle(){
  P_USER_ORACLE="${1}"
  ${COMMAND_SQL[@]} --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" << EOF
      GRANT SELECT ON SYS.DBA_RECYCLEBIN TO $P_USER_ORACLE;
      GRANT SELECT ON sys.dba_pending_transactions TO $P_USER_ORACLE;
      GRANT SELECT ON sys.pending_trans$ TO $P_USER_ORACLE;
      GRANT SELECT ON sys.dba_2pc_pending TO $P_USER_ORACLE;
      GRANT EXECUTE ON sys.dbms_xa TO $P_USER_ORACLE;
EOF
}

dropTableSpace(){
  P_TABLE_SPACE="${1}"
  echo "DROP TABLESPACE $P_TABLE_SPACE INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;" | ${COMMAND_SQL[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"  
}


createTableSpace(){
  P_TABLE_SPACE="${1}"
  P_FILE_TABLE_SPACE="${2}"
  P_TABLESPACE_PARAMS="${3}"

  [[ -z "${P_FILE_TABLE_SPACE// }" ]] && P_FILE_TABLE_SPACE="${TABLESPACE_NAME}.dbf"

  if [  "$( dirname $P_FILE_TABLE_SPACE )" == "." ]; then
    P_FILE_TABLE_SPACE="$ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PATH/$P_FILE_TABLE_SPACE"
  fi
  
  P_TABLESPACE_PARAMS="${P_TABLESPACE_PARAMS-$ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PARAMS}"
  [[ -z "${P_TABLESPACE_PARAMS// }" ]] && P_TABLESPACE_PARAMS="SIZE 10M AUTOEXTEND ON NEXT 5M"
  
  echo "Criando tablespace no oracle $P_TABLE_SPACE"
  mkdir -pv "$(dirname $P_FILE_TABLE_SPACE)"
  echo "CREATE TABLESPACE $P_TABLE_SPACE DATAFILE '$P_FILE_TABLE_SPACE' $P_TABLESPACE_PARAMS;" | ${COMMAND_SQL[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" 
 
}

createRoleUserDba(){
  P_NAME_ROLE="${1}"
  P_NAME_ROLE="${P_NAME_ROLE:-$ORACLE_ROLE_USER_DBA_NAME}"
  echo "Criando role dba $P_NAME_ROLE"
  ${COMMAND_SQL[@]} --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" << EOF
      create role $P_NAME_ROLE;
      grant all privileges to $P_NAME_ROLE;
      grant select any dictionary to $P_NAME_ROLE;
      GRANT CONNECT TO $P_NAME_ROLE;
      grant resource, DBA to $P_NAME_ROLE;
      grant create session, create table, create procedure, create trigger, create any directory, create view, create sequence, create synonym, create materialized view to $P_NAME_ROLE;
EOF
}

createRoleUserApp(){
  P_NAME_ROLE="${1}"
  P_NAME_ROLE="${P_NAME_ROLE:-$ORACLE_ROLE_USER_APP_NAME}"
  echo "Criando role user app $P_NAME_ROLE"
  ${COMMAND_SQL[@]} --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" << EOF
      create role $P_NAME_ROLE;
      grant all privileges to $P_NAME_ROLE;
      GRANT CONNECT TO $P_NAME_ROLE;
      grant select any dictionary to $P_NAME_ROLE;
      grant resource to $P_NAME_ROLE;
      grant create session to $P_NAME_ROLE;
EOF
}

createRoleFactory(){
  P_NAME_ROLE="${1}"
  if [ "${P_NAME_ROLE// }" == "$ORACLE_ROLE_USER_DBA_NAME" ]; then  
    createRoleUserDba "$P_NAME_ROLE" || echo "Não foi possível criar a role $P_NAME_ROLE"
    enableUserXAOracle "$P_NAME_ROLE"
  elif [ "${P_NAME_ROLE// }" == "$ORACLE_ROLE_USER_APP_NAME" ]; then  
    createRoleUserApp "$P_NAME_ROLE" || echo "Não foi possível criar a role $P_NAME_ROLE"  
    enableUserXAOracle "$P_NAME_ROLE"
  else
    echo "Role não criada $P_NAME_ROLE"  
  fi
}


createUserOracle(){
  P_USER_ORACLE="${1}"
  P_TABLE_SPACE="${2}"
  P_USER_ORACLE_PASSWORD="${3}"

  [[ -z "${P_TABLE_SPACE// }" ]] && P_TABLE_SPACE="$ORACLE_TABLE_SPACE_DEFAULT"
  [[ -z "${P_USER_ORACLE_PASSWORD// }" ]] && P_USER_ORACLE_PASSWORD="$P_USER_ORACLE"  

  echo "Criando usuário para o schema no oracle $P_USER_ORACLE"
  ${COMMAND_SQL[@]} --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" << EOF
      create user $P_USER_ORACLE identified by $P_USER_ORACLE_PASSWORD DEFAULT TABLESPACE $P_TABLE_SPACE TEMPORARY TABLESPACE TEMP;
      alter user $P_USER_ORACLE quota unlimited on users;
      ALTER USER $P_USER_ORACLE DEFAULT ROLE ALL;      
      GRANT UNLIMITED TABLESPACE TO $P_USER_ORACLE;
EOF
}

setRoleUser(){
  P_USER_ORACLE="${1}"
  P_ROLE="${2}"
  echo "Associando usuário $P_USER_ORACLE para a role $P_ROLE"
  echo "GRANT $P_ROLE TO $P_USER_ORACLE;" | ${COMMAND_SQL[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
}


dropUser(){
  P_USER_ORACLE="${1}"
  echo "DROP USER $P_USER_ORACLE CASCADE;"  | ${COMMAND_SQL[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" || echo "Não foi possível excluir o usuário $P_USER_ORACLE"
}


userExists(){
  P_USER_ORACLE="${1}"
  unset P_USER_CREATE
  ( echo "SELECT 'UserCreated' as result from all_users where username = '$P_USER_ORACLE' ;" | $FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} -f --connect $ORACLE_CREDENTIALS | grep UserCreated ) && P_USER_CREATE="true" || true
}