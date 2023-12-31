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
      --force-init)
      FORCE_INIT="${2}"
      shift # past argument
      shift # past argument
      ;; 
      --dir-startup-pids)
      DIR_STARTUP_PIDS="${2}"      
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


echo "Teste"
echo ""
echo ""

pushd $ORACLE_BASE

$ORACLE_BASE/$RUN_FILE ${PARAMS[@]}

popd

FILE_PID_START_SYSTEM="$DIR_STARTUP_PIDS/start-system.id"

echo "Teste2"

if [[ "$FORCE_INIT" == "true" || ! -e "$FILE_PID_START_SYSTEM" ]]; then
   /usr/sbin/startup-system.sh ${PARAMS[@]}
   mkdir -p $(dirname $FILE_PID_START_SYSTEM)
   echo $$ > "$FILE_PID_START_SYSTEM"
fi











