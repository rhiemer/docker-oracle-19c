#!/bin/bash
set -o errexit

PARAMS=()
PARAMS+=( $@ )

POSITIONAL=()
while [[ $# -gt 0 ]]
 do
   key="$1"
   case $key in
      -v|--verbose)
      set -x
      VERBOSE="--verbose"
      shift # past argument      
      ;;      
      --startup-system)
      STARTUP_SYSTEM="${2}"
      shift # past argument
      shift # past argument
      ;;
      --startup-sql-init)
      STARTUP_SQL_INIT="${2}"
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

trapErrorFinish(){   
  STATUS="$?"  
  if [ $STATUS -ne 0 ]; then
    echo "Erro ao executar as customizações iniciais." 1>&2
  fi
  return $STATUS
}


STARTUP_SYSTEM="${STARTUP_SYSTEM:-true}"
STARTUP_SQL_INIT="${STARTUP_SQL_INIT:-true}"

export ORA_FOLDER_TABLE_SPACES="${ORA_FOLDER_TABLE_SPACES:-/opt/oracle/oradata/$ORACLE_SID}"

trap 'trapErrorFinish' EXIT

if [[ "$STARTUP_SYSTEM" == "true" ]]; then
  $FOLDER_ORACLE_SCRIPTS/startup-system-prepare.sh ${PARAMS[@]}
fi

if [[ "$STARTUP_SQL_INIT" == "true" ]]; then
  $FOLDER_ORACLE_SCRIPTS/run-commands-prepare.sh -v ${PARAMS[@]}
fi