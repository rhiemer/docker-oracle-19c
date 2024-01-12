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
      --timeout)
      WAIT_TIME_OUT="${2}"
      shift # past argument
      shift # past argument
      ;;
      --timeout-unit)
      WAIT_TIME_OUT_UNIT="${2}"
      shift # past argument
      shift # past argument
      ;;
      --wait-file)
      WAIT_FILE="${2}"
      shift # past argument
      shift # past argument
      ;;
      --wait-grep)
      WAIT_GREP="${2}"
      shift # past argument
      shift # past argument
      ;;
      --sleep)
      SLEEP_LOOP="${2}"
      shift # past argument
      shift # past argument
      ;;
      --sleep-command)
      SLEEP_COMMAND="${2}"
      shift # past argument
      shift # past argument
      ;;
      --oracle-credentials)
      ORACLE_CREDENTIALS="${2}"
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

FILE_RESULT_TMP_WAIT=$(mktemp -t)
FILE_SQL_TMP=$(mktemp -t)

WAIT_GREP="${WAIT_GREP:-100%}"
WAIT_TIME_OUT="${WAIT_TIME_OUT:-5}"
WAIT_TIME_OUT_UNIT="${WAIT_TIME_OUT_UNIT:-minute}"
SLEEP_LOOP="${SLEEP_LOOP:-1}"
SLEEP_COMMAND="${SLEEP_COMMAND:-1}"
ORACLE_CREDENTIALS="${ORACLE_CREDENTIALS:-$SQL_PLUS_CREDENCIAIS_ADMIN}"

_WAIT_TIMEOUT="$WAIT_TIME_OUT $WAIT_TIME_OUT_UNIT"

waitOracle(){    
    endtime=$(date -ud "$_WAIT_TIMEOUT" +%s)
    while [[ $(date -u +%s) -le $endtime ]]
    do  
        if [ ! -z "${WAIT_FILE// }" ]; then        
          FILE_RESULT_TMP_WAIT="$WAIT_FILE"
          RESULT_SUCESS_COMMAND_START_WAIT="$WAIT_GREP"
        else
          RESULT_SUCESS_COMMAND_START_WAIT="ConnectionSucess"
          echo "SELECT '$RESULT_SUCESS_COMMAND_START_WAIT' as result FROM DUAL" | $FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} -f --connect $ORACLE_CREDENTIALS > $FILE_RESULT_TMP_WAIT || true
          if [ ! -z "${VERBOSE// }" ]; then
            echo "Resultado wait"
            cat $FILE_RESULT_TMP_WAIT
            echo ""
            echo ""
          fi         
        fi
        cat $FILE_RESULT_TMP_WAIT | grep "$RESULT_SUCESS_COMMAND_START_WAIT" && return 0 || true;
        sleep $SLEEP_LOOP;
    done
    echo "Oracle não se conectou. TIMEOUT - $WAIT_TIME_OUT." 1>&2
    return 1
}

waitOracle

sleep $SLEEP_COMMAND

if [ ! -z "${VERBOSE// }" ]; then
  echo "Executando ${POSITIONAL[@]}"
fi 

${POSITIONAL[@]}