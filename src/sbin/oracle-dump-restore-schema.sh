#!/bin/bash
set -o errexit

POSITIONAL=()
SCHEMAS=()

while [[ $# -gt 0 ]]
 do
   key="$1"
   case $key in
      -v|--verbose)
      set -x
      VERBOSE="${1}"
      shift # past argument      
      ;;
      --file)
      FILE_RESTORE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --directory)
      DIRECTORY="${2}"
      shift # past argument
      shift # past argument
      ;;      
      --schema)
      SCHEMAS+=("$2")
      shift # past argument
      shift # past argument
      ;;   
      --oracle-credentials)
      ORACLE_CREDENTIALS="${2}"
      shift # past argument
      shift # past argument
      ;;
      --log-file)
      LOG_FILE="${2}"
      shift # past argument
      shift # past argument
      ;;   
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

# restore positional parameters
set -- "${POSITIONAL[@]}"


createDirectoryOracle(){

  P_DIRECTORY="${1}"
  P_DIRECTORY_PATH="${2}"
  P_USER="${3}"

  echo "Criando diretório no oracle $P_DIRECTORY - $P_DIRECTORY_PATH. Permissões para o usuário $P_USER"

  mkdir -pv "$P_DIRECTORY_PATH"
  echo "CREATE OR REPLACE DIRECTORY $P_DIRECTORY AS $P_DIRECTORY_PATH;" | ${COMMAND[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
  echo "GRANT READ, WRITE ON DIRECTORY $P_DIRECTORY TO $P_USER;" | ${COMMAND[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
  
}

createTableSpace(){
  P_TABLE_SPACE="${1}"
  P_FILE_TABLE_SPACE="${2}"
  P_TABLESPACE_PARAMS="${3}"
  
  echo "Criando tablespace no oracle $P_TABLE_SPACE"
  echo "DROP TABLESPACE $P_TABLE_SPACE INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;"  | ${COMMAND[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" || echo "Não foi possível dropar a tablespace"
  mkdir -pv "$(dirname $P_FILE_TABLE_SPACE)"
  echo "CREATE TABLESPACE $P_TABLE_SPACE DATAFILE '$P_FILE_TABLE_SPACE' $P_TABLESPACE_PARAMS;" | ${COMMAND[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" 
 
}

createSchemaOracle(){
  P_USER_ORACLE="${1}"
  P_USER_ORACLE_PASSWORD="${2}"
  P_TABLE_SPACE="${3}"

  echo "Criando usuário para o schema no oracle $P_USER_ORACLE"

  echo "DROP USER $P_USER_ORACLE CASCADE;"  | ${COMMAND[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" || echo "Não foi possível excluir o usuário $P_USER_ORACLE"
  _FILE_CREATE_USER=$(mktemp -t)
  cat > $_FILE_CREATE_USER << _EOF
      create user $P_USER_ORACLE identified by $P_USER_ORACLE_PASSWORD DEFAULT TABLESPACE $P_TABLE_SPACE TEMPORARY TABLESPACE TEMP;
      alter user $P_USER_ORACLE quota unlimited on users;
      grant create session, create table, create procedure, create trigger, create any directory, create view, create sequence, create synonym, create materialized view to $P_USER_ORACLE;
      ALTER USER $P_USER_ORACLE QUOTA unlimited ON $P_TABLE_SPACE;
      GRANT UNLIMITED TABLESPACE TO $P_USER_ORACLE;

      GRANT SELECT ON SYS.DBA_RECYCLEBIN TO $P_USER_ORACLE;
      GRANT SELECT ON sys.dba_pending_transactions TO $P_USER_ORACLE;
      GRANT SELECT ON sys.pending_trans$ TO $P_USER_ORACLE;
      GRANT SELECT ON sys.dba_2pc_pending TO $P_USER_ORACLE;
      GRANT EXECUTE ON sys.dbms_xa TO $P_USER_ORACLE;
_EOF


if [ ! -z "${VERBOSE// }" ]; then
  cat $_FILE_CREATE_USER;
fi

$FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA" --file-sql "$_FILE_CREATE_USER"
 
}

createSchemaDefault(){
    _SCHEMAS_DEFAULT="${FILE_WITHOU_EXT^^}"  
    PREFIX_KEY="ORA_SCHEMA_$_SCHEMAS_DEFAULT"  
    
    _SCHEMAS_KEY="${PREFIX_KEY}_NAME"  
    _SCHEMAS="${!_SCHEMAS_KEY:-$_SCHEMAS_DEFAULT}"
    
    _SCHEMAS_PASSWORD_KEY="${PREFIX_KEY}_PASSWORD"
    _SCHEMAS_PASSWORD_DEFAULT="$_SCHEMAS"
    _SCHEMAS_PASSWORD="${!_SCHEMAS_PASSWORD_KEY:-$_SCHEMAS_PASSWORD_DEFAULT}"

    TABLESPACE_NAME_KEY="${PREFIX_KEY}_TABLESPACE_NAME"
    TABLESPACE_NAME_DEFAULT="TS_${_SCHEMAS^^}"
    TABLESPACE_NAME="${!TABLESPACE_NAME_KEY:-$TABLESPACE_NAME_DEFAULT}"

    TABLESPACE_FILE_KEY="${PREFIX_KEY}_TABLESPACE_FILE"
    TABLESPACE_FILE_DEFAULT="${TABLESPACE_NAME}.dbf"
    TABLESPACE_FILE="${!TABLESPACE_FILE_KEY:-$TABLESPACE_FILE_DEFAULT}"
    if [  "$( dirname $TABLESPACE_FILE )" == "." ]; then
      TABLESPACE_FILE="$ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PATH/$TABLESPACE_FILE"
    fi

    TABLESPACE_PARAMS_KEY="${PREFIX_KEY}_TABLESPACE_PARAMS"
    TABLESPACE_PARAMS=${!TABLESPACE_PARAMS_KEY:-$ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PARAMS}  

    LOG_FILE_KEY="${PREFIX_KEY}_LOG_FILE"
    LOG_FILE_SCHEMA_DEFAULT="${_SCHEMAS,,}.log"
    LOG_FILE_SCHEMA="${!LOG_FILE_KEY:-$LOG_FILE_SCHEMA_DEFAULT}"

    createTableSpace "$TABLESPACE_NAME" "$TABLESPACE_FILE_NAME" "$TABLESPACE_PARAMS"
    createSchemaOracle "$_SCHEMAS" "$_SCHEMAS_PASSWORD" "$TABLESPACE_NAME"

}

source "$FOLDER_ORACLE_SCRIPTS/sqlplus.sh"

ORACLE_CREDENTIALS="${ORACLE_CREDENTIALS:-$SQL_PLUS_CREDENCIAIS_ADMIN}"
FILE_BASENAME="$( basename $FILE_RESTORE )"
FILE_DIR="$( dirname $FILE_RESTORE )"
FILE_WITHOU_EXT="${FILE_BASENAME%%.*}"

ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PATH="${ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PATH:-/data-pump/restore/files}"
ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PARAMS="${ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PARAMS:-SIZE 10M AUTOEXTEND ON NEXT 5M}"

COMMAND=()
COMMAND+=($FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} -f )

_USER_CREDENTIAL="$( echo $ORACLE_CREDENTIALS |  awk -F '/' '{print $1}' )"

if [  -z "${DIRECTORY// }" ]; then  
 DIRECTORY=`python3 -c "import uuid;print(uuid.uuid1())"`
 createDirectoryOracle "$DIRECTORY" "$FILE_DIR" "$_USER_CREDENTIAL" || echo "Não foi possível criar o diretório no oracle para a pasta $FILE_DIR"
fi

if [  ! -z "${SCHEMAS// }" ]; then  
  _SCHEMAS=$(printf ",%s" "${SCHEMAS[@]}")
  _SCHEMAS="${_SCHEMAS:1}"
else
  createSchemaDefault
fi

LOG_FILE_DEFAULT="${FILE_WITHOU_EXT,,}.log"
LOG_FILE="${LOG_FILE:-$LOG_FILE_SCHEMA}"
LOG_FILE="${LOG_FILE:-$LOG_FILE_DEFAULT}"
if [  "$( dirname $LOG_FILE )" == "." ]; then
  LOG_FILE="$ORACLE_FOLDER_LOG_RESTORE/$LOG_FILE"
fi

$ORACLE_HOME/bin/impdp "$ORACLE_CREDENTIALS" dumpfile="$FILE_BASENAME" schemas="$_SCHEMAS" logfile="$LOG_FILE" directory="$DIRECTORY" ${POSITIONAL[@]}