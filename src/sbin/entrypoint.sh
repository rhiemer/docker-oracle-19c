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
      VERBOSE="${1}"
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

echo "Scripts Wait read oracle...."
$FOLDER_ORACLE_SCRIPTS/oracle-start-wait.sh "$FOLDER_ORACLE_SCRIPTS/prepare.sh" ${PARAMS[@]} &

echo ""
echo ""

pushd $ORACLE_BASE

$ORACLE_BASE/$RUN_FILE ${PARAMS[@]}
  
popd