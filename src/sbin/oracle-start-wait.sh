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
      ORACLE_CONNECT_WAIT_TIME_OUT="${2}"
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

source "$FOLDER_ORACLE_SCRIPTS/sqlplus.sh"

FILE_RESULT_TMP_WAIT=$(mktemp -t)
FILE_SQL_TMP=$(mktemp -t)

cat > $FILE_SQL_TMP <<EOF
   SELECT 'ConnectionSucess' as result FROM DUAL
EOF

waitOracle(){    
    endtime=$(date -ud "$ORACLE_CONNECT_WAIT_TIME_OUT" +%s)
    while [[ $(date -u +%s) -le $endtime ]]
    do  
        echo ""
        $FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} --connect $SQL_PLUS_CREDENCIAIS_PWD --file-sql $FILE_SQL_TMP --file-result $FILE_RESULT_TMP_WAIT
        echo ""
        if [ ! -z "${VERBOSE// }" ]; then
          echo "Resultado wait"
          cat $FILE_RESULT_TMP_WAIT
          echo ""
          echo ""
        fi         
        cat $FILE_RESULT_TMP_WAIT | grep "$RESULT_SUCESS_COMMAND_START_WAIT" && return 0 || true;
        sleep $ORACLE_CONNECT_SLEEP_TIME_OUT;
    done
    echo "Oracle não se conectou. TIMEOUT - $ORACLE_CONNECT_WAIT_TIME_OUT." 1>&2
    return 1
}

ORACLE_CONNECT_WAIT_TIME_OUT="${ORACLE_CONNECT_WAIT_TIME_OUT:-30 minute}"
ORACLE_CONNECT_SLEEP_TIME_OUT="${ORACLE_CONNECT_SLEEP_TIME_OUT:-300}"
ORACLE_CONNECT_SLEEP_COMMAND="${ORACLE_CONNECT_SLEEP_COMMAND:-5}"

waitOracle

sleep $ORACLE_CONNECT_SLEEP_COMMAND

echo "Oracle conectado, executando comandos de inicialização..."

if [ ! -z "${VERBOSE// }" ]; then
  echo "Executando ${POSITIONAL[@]}"
fi 

${POSITIONAL[@]}