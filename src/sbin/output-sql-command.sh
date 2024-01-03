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

FILE_RESULT_TMP=$(mktemp -t)
_FILE_RESULT="${FILE_RESULT:-$FILE_RESULT_TMP}"

trapRemoveFileResult(){   
  STATUS="$?"  
  rm -rf $FILE_RESULT_TMP || true  
  return $STATUS
}

trap 'trapRemoveFileResult' EXIT

sqlplus -s /nolog << EOF

      CONNECT $ORACLE_CONNECT;

      whenever sqlerror exit sql.sqlcode;
      
      set termout off;
      
      spool $_FILE_RESULT;

      $( [[ ! -z "${FILE_SQL// }" ]] && tr '\n' ' ' < $FILE_SQL || echo ${POSITIONAL[@]} );
      
      spool OFF;

      exit;

EOF

if [ -z "${FILE_RESULT// }" ]; then
  cat $_FILE_RESULT
fi 




