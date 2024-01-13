#!/bin/bash
set -o errexit

POSITIONAL=()

while [[ $# -gt 0 ]]
 do
   key="$1"
   case $key in
      -v|--verbose)
      set -x
      VERBOSE="${1}"
      shift # past argument      
      ;;
      --path)
      DIRECTORY="${2}"
      shift # past argument
      shift # past argument
      ;;
      --oracle-credentials)
      ORACLE_CREDENTIALS="${2}"
      shift # past argument
      shift # past argument
      ;;
      --current-schema)
      RESTORE_POS_EXEC_CURRENT_SCHEMA="${2}"
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

ORACLE_CREDENTIALS="${ORACLE_CREDENTIALS:-$SQL_PLUS_CREDENCIAIS_ADMIN}"

_PATHS=()
_PATHS+=( "$DIRECTORY" "$DIRECTORY/$ORACLE_DATAPUMP_RESTORE_POS_PATH_NAME" "$DIRECTORY/${ORACLE_DATAPUMP_RESTORE_POS_PATH_NAME}.sql" )

_FILES=()

for _PATH in ${_PATHS[@]} 
do
  _PATH_BASE_NAME="$(basename $_PATH)"
  if [ "${_PATH_BASE_NAME}" != "$ORACLE_DATAPUMP_RESTORE_POS_PATH_NAME"  ]; then     
    continue;
  fi
  if [  -f "${_PATH}" ]; then  
    _FILES+=( "$_PATH" )
  else
    _FILES+=( $( find "$_PATH" -mindepth 1 -type f -name *.sql | sort ) )
  fi  
  break;
done


if [ -z "${_FILES// }" ]; then  
  exit 0;
fi


PREFIX_KEY_POS_RESTORE_EXEC="${ORACLE_DATAPUMP_RESTORE_POS_PREFIX_ENVS}_${RESTORE_POS_EXEC_CURRENT_SCHEMA}"  
KEY_POS_RESTORE_EXEC_PARAMS="${PREFIX_KEY_POS_RESTORE_EXEC}_PARAMS"
_POS_RESTORE_EXEC_PARAMS="${!KEY_POS_RESTORE_EXEC_PARAMS:-$ORACLE_DATAPUMP_RESTORE_POS_EXEC_PARAMS}"

for _FILE in ${_FILES[@]} 
do 
  echo "Executando Arquivo Pos Restore $(basename $_FILE)"
  echo ""
  eval $FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} --connect "$ORACLE_CREDENTIALS" --file-sql "$_FILE" --current-schema $RESTORE_POS_EXEC_CURRENT_SCHEMA $( echo $_POS_RESTORE_EXEC_PARAMS )
  echo "Arquivo Pos Restore $(basename $_FILE) executado com sucesso $_LOG"
  echo ""
done

