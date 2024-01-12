#!/bin/bash
set -o errexit

POSITIONAL=()
while [[ $# -gt 0 ]]
 do
   key="$1"
   case $key in
      -v|--verbose)
      VERBOSE="${1}"
      set -x
      shift # past argument
      ;;
      -f|--follow)
      FOLLOW="${1}"
      shift # past argument      
      ;;
      --buffer-timeout)
      BUFFER_TIMEOUT="${1}"
      shift # past argument      
      shift # past argument      
      ;;
      --file-sql)
      FILE_SQL="${2}"
      shift # past argument
      shift # past argument
      ;;
      --one-command-line)
      ONE_COMMAND_LINE="${2}"
      shift # past argument      
      shift # past argument      
      ;;
      --ignore-erros)
      IGNORE_ERROS="${2}"
      shift # past argument      
      shift # past argument      
      ;;
      --replace-vars)
      REPLACE_VARS_SQL_COMMAND="${2}"
      shift # past argument
      shift # past argument
      ;;
      --connect)
      ORACLE_CONNECT="${2}"
      shift # past argument
      shift # past argument
      ;;
      --sleep)
      ORACLE_CONNECT_SLEEP_TIME_OUT="${2}"
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

REPLACE_VARS_SQL_COMMAND="${REPLACE_VARS_SQL_COMMAND:-true}"
BUFFER_TIMEOUT="${BUFFER_TIMEOUT:-1}"  
if [[ ! -z "${BUFFER_TIMEOUT// }" ]]; then
  _BUFFER_TIMEOUT=("-t" "$BUFFER_TIMEOUT")
fi

FILE_TMP_BUFFER="$( mktemp )"


msgFileBuffer(){
  unset MSG
  #lendo o buffer
  while read ${_BUFFER_TIMEOUT[@]} MSG; do
      if [[ ! -z "$MSG" ]]; then
        echo "$MSG" >> $FILE_TMP_BUFFER
      fi
  done
}


if [[ ! -z "${FOLLOW// }" ]]; then
  FILE_SQL="$FILE_TMP_BUFFER"
  #esperando o stdout de um pipe após a execução de um comando  ( | ) 
  msgFileBuffer   
fi



trapRemoveFileResult(){   
  STATUS="$?"  
  rm -rf $FILE_TMP_BUFFER || true
  if [  -z "${VERBOSE// }" ]; then
    rm -rf $FILE_EXEC || true
    rm -rf $FILE_EXEC2 || true
  fi  
  return $STATUS
}


FILE_EXEC=$(mktemp -t)
FILE_EXEC2=$(mktemp -t)

if [[ ! -z "${FILE_SQL// }" ]]; then
   cp -rf "$FILE_SQL" "$FILE_EXEC"
else
   echo ${POSITIONAL[@]} > "$FILE_EXEC"
fi 

find "$FILE_EXEC" -type f  -exec sh -c 'tr -d "\r" < "{}" > "{}".new && mv "{}".new "{}"' -- {} \; -exec chmod +x {} \;  
if [[ "$REPLACE_VARS_SQL_COMMAND" == "true" ]]; then
  envsubst "`printf '${%s} ' $(sh -c "env|cut -d'=' -f1")`" < "$FILE_EXEC" > "$FILE_EXEC2"  
else 
  cat $FILE_EXEC > $FILE_EXEC2
fi

trap 'trapRemoveFileResult' EXIT


sqlplus -s /nolog << EOF

      
      $( [[ "$IGNORE_ERROS" != "true" ]] && echo "WHENEVER OSERROR EXIT 68;" )
      $( [[ "$IGNORE_ERROS" != "true" ]] && echo "whenever sqlerror exit sql.sqlcode;" )
      
      set sqlblanklines on;
      set termout on;
      
      CONNECT $ORACLE_CONNECT;
      
      @$FILE_EXEC2;
      
      exit;

EOF


