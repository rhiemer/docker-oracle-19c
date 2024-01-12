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
  if [ "${STATUS// }" != "0" ]; then
    echo "Erro ao executar as customizações iniciais." 1>&2
  fi
  return $STATUS
}


setEnv(){
  KEY="$1"
  VALUE="$2"   
  export "$KEY=\"$VALUE\""
  if [  ! -z "${BASH_ENV// }" ]; then  
    echo "export $KEY=\"$VALUE\"" >> "$BASH_ENV"
  fi
}

source "$FOLDER_ORACLE_SCRIPTS/sqlplus.sh"

setEnv "ORA_FOLDER_TABLE_SPACES" "${ORA_FOLDER_TABLE_SPACES:-/opt/oracle/oradata/$ORACLE_SID}"
setEnv "ORA_WAIT_LOG_INIT" "${ORA_WAIT_LOG_INIT:-/opt/oracle/cfgtoollogs/dbca/${ORACLE_SID}/${ORACLE_SID}.log}"
setEnv "ORA_SQL_CREDENTIALS_ROOT" "${ORA_SQL_CREDENTIALS_ROOT:-$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA}"

STARTUP_SYSTEM="${STARTUP_SYSTEM:-true}"
STARTUP_SQL_INIT="${STARTUP_SQL_INIT:-true}"
CREATE_USERS_ENVS="${CREATE_USERS_ENVS:-true}"

trap 'trapErrorFinish' EXIT

echo "Oracle incializado, executando customizações..."

if [[ "$STARTUP_SYSTEM" == "true" ]]; then
  $FOLDER_ORACLE_SCRIPTS/startup-system-prepare.sh ${PARAMS[@]}
fi

if [[ "$CREATE_USERS_ENVS" == "true" ]]; then
  echo "Criando usuários envs..."
  echo ""
  $FOLDER_ORACLE_SCRIPTS/oracle-create-user-envs.sh ${PARAMS[@]}
fi

if [[ "$STARTUP_SQL_INIT" == "true" ]]; then
  $FOLDER_ORACLE_SCRIPTS/run-commands-prepare.sh ${PARAMS[@]}
fi



echo ""
echo "Customizações executadas com sucesso."
