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
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

# restore positional parameters
set -- "${POSITIONAL[@]}"

STARTUP_SYSTEM="${STARTUP_SYSTEM:-true}"

if [[ "$STARTUP_SYSTEM" == "true" ]]; then
  $FOLDER_ORACLE_SCRIPTS/startup-system-prepare.sh -v ${PARAMS[@]}
fi
