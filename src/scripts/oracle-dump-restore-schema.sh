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
      --oracle-credentials)
      ORACLE_CREDENTIALS="${2}"
      shift # past argument
      shift # past argument
      ;;
      --file)
      FILE_RESTORE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --prefix-key)
      PREFIX_KEY="${2}"
      shift # past argument
      shift # past argument
      ;;
      --user-from)
      USER_DATAPUMP_RESTORE_FROM="${2}"
      shift # past argument
      shift # past argument
      ;;
      --user-to)
      USER_DATAPUMP_RESTORE_TO="${2}"
      shift # past argument
      shift # past argument
      ;;
      --type)
      TYPE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --create-user)
      CREATE_USER="${2}"
      shift # past argument
      shift # past argument
      ;;
      --user-to-role-type)
      ROLE_TYPE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --user-to-recreate)
      USER_RECREATE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --create-table-space)
      TABLE_SPACE_CREATE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --recreate-table-space)
      TABLE_SPACE_RECREATE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --params)
      RESTORE_PARAMS="${2}"
      shift # past argument
      shift # past argument
      ;;
      --folder-log)
      FOLDER_LOG="${2}"
      shift # past argument
      shift # past argument
      ;;
      --file-log)
      FILE_LOG="${2}"
      shift # past argument
      shift # past argument
      ;;
      --create-directory)
      CREATE_DIRECTORY="${2}"
      shift # past argument
      shift # past argument
      ;;
      --directory)
      DIRECTORY_DATAPUMP_RESTORE="${2}"
      shift # past argument
      shift # past argument
      ;;      
      --create-directory-log)
      CREATE_DIRECTORY_LOG="${2}"
      shift # past argument
      shift # past argument
      ;;
      --directory-log)
      DIRECTORY_DATAPUMP_RESTORE_LOG="${2}"
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

source "$FOLDER_ORACLE_SCRIPTS/sqlplus.sh"
source "$FOLDER_ORACLE_SCRIPTS/functions.sh"

createDirectoryRestore(){
  _CREATE_DIRECTORY_KEY="${PREFIX_KEY}_CREATE_DIRECTORY"
  _CREATE_DIRECTORY="${!_CREATE_DIRECTORY_KEY:-$CREATE_DIRECTORY}"
  _CREATE_DIRECTORY="${_CREATE_USER:-$ORACLE_DATAPUMP_RESTORE_CREATE_DIRECTORY}"

  _DIRECTORY_NAME_KEY="${PREFIX_KEY}_DIRECTORY_NAME"
  DIRECTORY_DATAPUMP_RESTORE="${!_DIRECTORY_NAME_KEY:-$DIRECTORY_DATAPUMP_RESTORE}"  

  if [[ "$_CREATE_DIRECTORY" == "true" ]]; then
      if [  ! -z "${DIRECTORY_DATAPUMP_RESTORE// }" ]; then  
        createDirectoryOracle "$DIRECTORY_DATAPUMP_RESTORE" "$FILE_DIR"  || echo "Não foi possível criar o diretório no oracle para a pasta $FILE_DIR"
      else
        createDirectoryOracleAuth "DIR_IMP" "$FILE_DIR" || echo "Não foi possível criar o diretório no oracle para a pasta $FILE_DIR"
        DIRECTORY_DATAPUMP_RESTORE="$_DIRECTORY"
      fi
  fi
}


createDirectoryLog(){
  _CREATE_DIRECTORY_LOG_KEY="${PREFIX_KEY}_CREATE_DIRECTORY_LOG"
  _CREATE_DIRECTORY_LOG="${!_CREATE_DIRECTORY_LOG_KEY:-$CREATE_DIRECTORY_LOG}"
  _CREATE_DIRECTORY_LOG="${_CREATE_DIRECTORY_LOG:-$ORACLE_DATAPUMP_RESTORE_CREATE_DIRECTORY_LOG}"

  _DIRECTORY_LOG_NAME_KEY="${PREFIX_KEY}_DIRECTORY_LOG_NAME"
  DIRECTORY_DATAPUMP_RESTORE_LOG="${!_DIRECTORY_LOG_NAME_KEY:-$DIRECTORY_DATAPUMP_RESTORE_LOG}"  

  FILE_LOG_DATAPUMP_RESTORE_DIR="$(dirname $FILE_LOG_DATAPUMP_RESTORE)"

  if [[ "$_CREATE_DIRECTORY_LOG" == "true" ]]; then
      if [  ! -z "${DIRECTORY_DATAPUMP_RESTORE_LOG// }" ]; then  
        createDirectoryOracle "$DIRECTORY_DATAPUMP_RESTORE_LOG" "$FILE_LOG_DATAPUMP_RESTORE_DIR"  || echo "Não foi possível criar o diretório no oracle para a pasta $FILE_LOG_DATAPUMP_RESTORE_DIR"
      else
        createDirectoryOracleAuth "DIR_IMP_LOG" "$FILE_LOG_DATAPUMP_RESTORE_DIR" || echo "Não foi possível criar o diretório no oracle para a pasta $FILE_LOG_DATAPUMP_RESTORE_DIR"
        DIRECTORY_DATAPUMP_RESTORE_LOG="$_DIRECTORY"
      fi
  fi

  FILE_LOG_DATAPUMP_RESTORE="$DIRECTORY_DATAPUMP_RESTORE_LOG:$( basename $FILE_LOG_DATAPUMP_RESTORE)"
}

FILE_BASENAME="$( basename $FILE_RESTORE )"
FILE_DIR="$( dirname $FILE_RESTORE )"
FILE_WITHOU_EXT="${FILE_BASENAME%%.*}"
FILE_WITHOU_EXT="${FILE_WITHOU_EXT//-/_}"
FILE_WITHOU_EXT_UPP="${FILE_WITHOU_EXT^^}"
PREFIX_KEY_DEFAULT="${ORACLE_DATAPUMP_RESTORE_PREFIX_ENVS}_$FILE_WITHOU_EXT_UPP"
PREFIX_KEY="${PREFIX_KEY:-$PREFIX_KEY_DEFAULT}"

_USER_FROM_KEY="${PREFIX_KEY}_USER_FROM"
USER_DATAPUMP_RESTORE_FROM="${!_USER_FROM_KEY:-$USER_DATAPUMP_RESTORE_FROM}"
USER_DATAPUMP_RESTORE_FROM="${_USER_NAME:-$FILE_WITHOU_EXT_UPP}"

_USER_TO_KEY="${PREFIX_KEY}_USER_TO"
USER_DATAPUMP_RESTORE_TO="${!_USER_TO_KEY:-$USER_DATAPUMP_RESTORE_TO}"
USER_DATAPUMP_RESTORE_TO="${USER_DATAPUMP_RESTORE_TO:-$USER_DATAPUMP_RESTORE_FROM}"

_TYPE_KEY="${PREFIX_KEY}_TYPE"
_TYPE="${!_TYPE_KEY:-$TYPE}"
_TYPE="${_TYPE:-$ORACLE_DATAPUMP_RESTORE_TYPE}"

_CREATE_USER_KEY="${PREFIX_KEY}_CREATE_USER"
_CREATE_USER="${!_CREATE_USER_KEY:-$CREATE_USER}"
_CREATE_USER="${_CREATE_USER:-$ORACLE_DATAPUMP_RESTORE_USER_CREATE}"

if [[ "$_CREATE_USER" == "true" ]]; then
  _USERS_CREATES=( $(echo "$USER_DATAPUMP_RESTORE_TO" | tr "," " ") )
  for _USER_CREATE in ${_USERS_CREATES[@]} 
  do        
    echo "Criando usuário para o dump $_USER_CREATE"
    $FOLDER_ORACLE_SCRIPTS/oracle-create-user.sh ${VERBOSE} --user-name-envs "$_USER_CREATE" \
                                                            --role-type "${ROLE_TYPE:-$ORACLE_DATAPUMP_RESTORE_ROLE_TYPE}" \
                                                            --user-recreate "${USER_RECREATE:-$ORACLE_DATAPUMP_RESTORE_USER_RECREATE}" \
                                                            --create-table-space "${TABLE_SPACE_CREATE:-$ORACLE_DATAPUMP_RESTORE_TABLE_SPACE_CREATE}" \
                                                            --table-space-recreate "${TABLE_SPACE_RECREATE:-$ORACLE_DATAPUMP_RESTORE_TABLE_SPACE_RECREATE}"
  done
fi  

_FOLDER_LOG_KEY="${PREFIX_KEY}_LOG_FOLDER"
FOLDER_LOG="${!_FOLDER_LOG_KEY:-$FOLDER_LOG}"
FOLDER_LOG="${FOLDER_LOG:-$ORACLE_DATAPUMP_RESTORE_LOG_FOLDER}"

_FILE_LOG_KEY="${PREFIX_KEY}_LOG_FILE_NAME"
FILE_LOG_DEFAULT="${FILE_WITHOU_EXT,,}.log"
FILE_LOG="${!_FILE_LOG_KEY:-$FILE_LOG}"
FILE_LOG="${FILE_LOG:-$FILE_LOG_DEFAULT}"

FILE_LOG_DATAPUMP_RESTORE="$FOLDER_LOG/$FILE_LOG"
mkdir -pv "$(dirname $FILE_LOG_DATAPUMP_RESTORE)" || true
touch "$FILE_LOG_DATAPUMP_RESTORE"
FILE_LOG_DATAPUMP_RESTORE="$(realpath $FILE_LOG_DATAPUMP_RESTORE)"

if [[ "$_TYPE" == "impdp" ]]; then
  createDirectoryRestore
  createDirectoryLog
fi

USER_DATAPUMP_RESTORE_FILE="$(realpath $FILE_RESTORE)"

_RESTORE_GLOBAL_KEY="ORACLE_DATAPUMP_RESTORE_PARAMS_${_TYPE^^}"
_RESTORE_PARAMS_DEFAULT="${!_RESTORE_GLOBAL_KEY}"
_RESTORE_PARAMS_DEFAULT="${RESTORE_PARAMS:-$_RESTORE_PARAMS_DEFAULT}"

_RESTORE_PARAMS_KEY="${PREFIX_KEY}_PARAMS"
_RESTORE_PARAMS="${!_RESTORE_PARAMS_KEY:-$_RESTORE_PARAMS_DEFAULT}"
_RESTORE_PARAMS_VALUES=( $( eval echo $_RESTORE_PARAMS ) )

$ORACLE_HOME/bin/$_TYPE "$ORACLE_CREDENTIALS" ${_RESTORE_PARAMS_VALUES[@]} 