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
      --file-result)
      FILE_RESULT="${2}"
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

BUFFER_TIMEOUT="${BUFFER_TIMEOUT:-1}"  
if [[ ! -z "${BUFFER_TIMEOUT// }" ]]; then
  _BUFFER_TIMEOUT=("-t" "$BUFFER_TIMEOUT")
fi

FILE_TMP_BUFFER="$( mktemp )"
FILE_RESULT_TMP=$(mktemp -t)
_FILE_RESULT="${FILE_RESULT:-$FILE_RESULT_TMP}"


msgFileBuffer(){
  unset MSG
  #lendo o buffer
  while read ${_BUFFER_TIMEOUT[@]} MSG; do
      if [[ ! -z "$MSG" ]]; then
        echo "$MSG" > $FILE_TMP_BUFFER
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
  if [ $STATUS -ne 0 ] ; then
    echo "Erro ao executar o script. $STATUS" 1>&2
    cat $_FILE_RESULT 1>&2    
  elif [ -z "${FILE_RESULT// }" ]; then
    cat $_FILE_RESULT
  fi
  rm -rf $FILE_TMP_BUFFER || true
  if [  -z "${VERBOSE// }" ]; then
    rm -rf $FILE_RESULT_TMP || true
  else
    echo "" >> $FILE_RESULT_TMP
    if [ ! -z "${FILE_SQL// }" ]; then
     touch $FILE_SQL
     cat $FILE_SQL >> $FILE_RESULT_TMP
    else
     echo ${POSITIONAL[@]} >> $FILE_RESULT_TMP
    fi 
  fi  
  return $STATUS
}

trap 'trapRemoveFileResult' EXIT

sqlplus -s /nolog << EOF

      CONNECT $ORACLE_CONNECT;
      
      WHENEVER OSERROR EXIT 68;
      whenever sqlerror exit sql.sqlcode;
      
      set termout off;
      set sqlblanklines on;
      
      spool $_FILE_RESULT;

      $( [[ ! -z "${FILE_SQL// }" ]] && tr '\n' ' ' < $FILE_SQL || echo ${POSITIONAL[@]} );
      
      spool OFF;

      exit;

EOF

