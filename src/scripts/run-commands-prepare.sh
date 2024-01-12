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
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

# restore positional parameters
set -- "${POSITIONAL[@]}"

FILE_STARTUP_SQL_LOG="${FILE_STARTUP_SQL_LOG:-$DIR_STARTUP_SQL_LOGS/sql-exec.log}"
FORCE_RUN_SQL_INIT="${FORCE_RUN_SQL_INIT:-$FORCE_INIT}"

if [ ! -d "${FOLDER_INIT_DB}" ]; then
  exit 0;
fi

echo "Executando comandos e sqls iniciais..."
mkdir -p "$DIR_STARTUP_SQL"
mkdir -p "$(dirname $FILE_STARTUP_SQL_LOG)"
$FOLDER_ORACLE_SCRIPTS/run-commands.sh --folder-scripts "$FOLDER_INIT_DB" --folder-scripts-exec "$DIR_STARTUP_SQL" --force "$FORCE_RUN_SQL_INIT" ${PARAMS[@]} | tee -a $FILE_STARTUP_SQL_LOG 
