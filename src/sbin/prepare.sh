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
      ORACLE_FORCE_INIT="${2}"
      shift # past argument
      shift # past argument
      ;; 
      --file-pid-init)
      FILE_PID_INIT="${2}"      
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

set -x

FILE_PID_INIT="$DIR_STARTUP_PIDS/init.id"

if [[ "$ORACLE_FORCE_INIT" == "true" || ! -e "$FILE_PID_INIT" ]]; then
   /usr/sbin/init.sh ${PARAMS[@]}
   mkdir -p $(dirname $FILE_PID_INIT)
   echo $$ > "$FILE_PID_INIT"  
fi