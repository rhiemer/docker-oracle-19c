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
      --create-log-file)
      ORACLE_DATA_PUMP_RESTORE_CREATE_LOG_FILE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --log-directory)
      ORACLE_DATA_PUMP_RESTORE_LOG_DIRECTORY="${2}"
      shift # past argument
      shift # past argument
      ;;
      --create-directory-imp)
      CREATE_DIRECTORY_RESTORE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --create-schema-file)
      CREATE_SCHEMA_FILE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --full-import)
      ORACLE_DATA_PUMP_RESTORE_FULL="${2}"
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
  echo "CREATE OR REPLACE DIRECTORY $P_DIRECTORY AS '$P_DIRECTORY_PATH';" | ${COMMAND[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
  echo "GRANT READ, WRITE ON DIRECTORY $P_DIRECTORY TO $P_USER;" | ${COMMAND[@]}  --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
  
}

createDirectoryOracleAuth(){

  P_PREFIX="${1}"
  P_DIRECTORY_PATH="${2}"
  P_USER="${3}"

  _DIRECTORY=`${PYTHON_CMD[@]} -c "import uuid;print(uuid.uuid1())"`
  _DIRECTORY="${_DIRECTORY%%-*}"
  _DIRECTORY="${_DIRECTORY^^}"
  _DIRECTORY="${P_PREFIX}_${DIRECTORY}"

  createDirectoryOracle "$_DIRECTORY" "$P_USER" "$P_PREFIX"  
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
    PREFIX_KEY="ORA_SCHEMA_${_SCHEMAS_DEFAULT}"  
    
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

    FULL_IMPORT_KEY="${PREFIX_KEY}_FULL_IMPORT"    
    FULL_IMPORT_SCHEMA="${!FULL_IMPORT_KEY}"

    createTableSpace "$TABLESPACE_NAME" "$TABLESPACE_FILE" "$TABLESPACE_PARAMS"
    createSchemaOracle "$_SCHEMAS" "$_SCHEMAS_PASSWORD" "$TABLESPACE_NAME"

}

source "$FOLDER_ORACLE_SCRIPTS/sqlplus.sh"

PYTHON_CMD="${PYTHON_CMD:-python}"
ORACLE_CREDENTIALS="${ORACLE_CREDENTIALS:-$SQL_PLUS_CREDENCIAIS_ADMIN}"
FILE_BASENAME="$( basename $FILE_RESTORE )"
FILE_DIR="$( dirname $FILE_RESTORE )"
FILE_WITHOU_EXT="${FILE_BASENAME%%.*}"

ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PATH="${ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PATH:-$ORA_FOLDER_TABLE_SPACES}"
ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PARAMS="${ORACLE_DATA_PUMP_RESTORE_TABLESPACE_PARAMS:-SIZE 10M AUTOEXTEND ON NEXT 5M}"
ORACLE_FOLDER_LOG_RESTORE="${ORACLE_FOLDER_LOG_RESTORE:-"/init/logs/restore"}"

COMMAND=()
COMMAND+=($FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} -f )

_USER_CREDENTIAL="$( echo $ORACLE_CREDENTIALS |  awk -F '/' '{print $1}' )"

if [[ "$CREATE_DIRECTORY_RESTORE" == "true" ]]; then
  if [  ! -z "${DIRECTORY// }" ]; then  
    createDirectoryOracle "$DIRECTORY" "$FILE_DIR" "$_USER_CREDENTIAL" || echo "Não foi possível criar o diretório no oracle para a pasta $FILE_DIR"
  else
    createDirectoryOracleAuth "DIR_IMP" "$FILE_DIR" "$_USER_CREDENTIAL" || echo "Não foi possível criar o diretório no oracle para a pasta $FILE_DIR"
    DIRECTORY="$_DIRECTORY"
  fi
fi

if [[ "$CREATE_SCHEMA_FILE" == "true" ]]; then
  createSchemaDefault
  if [ -z "${SCHEMAS// }" ]; then
   SCHEMAS="$_SCHEMAS" 
  fi
fi

if [[ "$ORACLE_DATA_PUMP_RESTORE_CREATE_LOG_FILE" == "true" ]]; then
  LOG_FILE_DEFAULT="${FILE_WITHOU_EXT,,}.log"
  LOG_FILE="${LOG_FILE:-$LOG_FILE_SCHEMA}"
  LOG_FILE="${LOG_FILE:-$LOG_FILE_DEFAULT}"
fi

if [[  ! -z "${DIRECTORY// }" && ! -z "${ORACLE_DATA_PUMP_RESTORE_LOG_DIRECTORY// }" ]]; then  
   mkdir -pv $ORACLE_DATA_PUMP_RESTORE_LOG_DIRECTORY || true
   createDirectoryOracleAuth "DIR_IMP_LOG" "$ORACLE_DATA_PUMP_RESTORE_LOG_DIRECTORY" "$_USER_CREDENTIAL" || echo "Não foi possível criar o diretório no oracle para a pasta de logs $ORACLE_DATA_PUMP_RESTORE_LOG_DIRECTORY"
   LOG_FILE="$_DIRECTORY:$( basename $LOG_FILE)"
fi

PARAMS_EXEC=()

if [  ! -z "${DIRECTORY// }" ]; then 
  PARAMS_EXEC+=( directory="$DIRECTORY" )
fi

FULL_IMPORT="${FULL_IMPORT:-$FULL_IMPORT_SCHEMA}"
FULL_IMPORT="${FULL_IMPORT:-$ORACLE_DATA_PUMP_RESTORE_FULL}"
if [[ "$FULL_IMPORT" == "true" || -z "${SCHEMAS// }"  ]]; then
  PARAMS_EXEC+=( FULL=y )
else 
  _SCHEMAS_EXEC=$(printf ",%s" "${SCHEMAS[@]}")
  _SCHEMAS_EXEC="${_SCHEMAS_EXEC:1}"
  PARAMS_EXEC+=( schemas="$_SCHEMAS_EXEC" )
fi

if [  ! -z "${LOG_FILE// }" ]; then  
  PARAMS_EXEC+=( logfile="$LOG_FILE" )
else  
  PARAMS_EXEC+=( NOLOGFILE=Y )
fi


$ORACLE_HOME/bin/impdp "$ORACLE_CREDENTIALS" dumpfile="$FILE_BASENAME" ${PARAMS_EXEC[@]} ${POSITIONAL[@]}