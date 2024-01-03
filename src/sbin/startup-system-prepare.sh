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
      --force-startup-system)
      FORCE_STARTUP_SYSTEM="${2}"
      shift # past argument
      shift # past argument
      ;; 
      --dir-startup-pids)
      DIR_STARTUP_PIDS="${2}"      
      shift # past argument
      shift # past argument
      ;;       
      --file-pid-start-system)
      FILE_PID_START_SYSTEM="${2}"      
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

trapFileResult(){   
   STATUS="$?"  
   echo ""
   cat $FILE_SQL
   echo ""
   return $STATUS
}


FORCE_STARTUP_SYSTEM="${FORCE_STARTUP_SYSTEM:-$FORCE_INIT}"
FILE_PID_START_SYSTEM="${FILE_PID_START_SYSTEM:-$DIR_STARTUP_PIDS/start-system.id}"

if [[ "$FORCE_STARTUP_SYSTEM" == "true" || ! -e "$FILE_PID_START_SYSTEM" ]]; then
   FILE_SQL=$(mktemp -t)
   
   echo "Configurações padrões para os usuários SYS e SYSTEM..."
   echo ""

   trap 'trapFileResult' EXIT
   
   $FOLDER_ORACLE_SCRIPTS/startup-system.sh ${PARAMS[@]} | tee $FILE_SQL
   
   echo ""
   
   mkdir -p $(dirname $FILE_PID_START_SYSTEM)
   
   echo "" >> $FILE_PID_START_SYSTEM
   cat $FILE_SQL >> $FILE_PID_START_SYSTEM

   echo "Configurações padrões para os usuários SYS e SYSTEM executados com sucesso."

fi
