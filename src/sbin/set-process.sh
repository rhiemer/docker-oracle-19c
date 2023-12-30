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
      --process)
      ORACLE_PROCESS="${2}"      
      shift # past argument
      shift # past argument
      ;; 
      --scope)
      ORACLE_PROCESS_SCOPE="${2}"      
      shift # past argument
      shift # past argument
      ;; 
	  --force-process)
      ORACLE_FORCE_PROCESS="${1}"      
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

source "/usr/sbin/sqlplus.sh"

ORACLE_PROCESS_SCOPE=${ORACLE_PROCESS_SCOPE-'spfile'}

setProcess(){
	echo "Alterando processos do oracle para $ORACLE_PROCESS. Após o oracle será reiniciado."

	echo "alter system set PROCESSES=$ORACLE_PROCESS scope=$ORACLE_PROCESS_SCOPE;" | $SQL_PLUS_COMMAND_ADMIN
   if [ ! -z "$ORACLE_SESSIONS" ] ; then
     echo "alter system set sessions=$ORACLE_SESSIONS scope=$ORACLE_PROCESS_SCOPE;" | $SQL_PLUS_COMMAND_ADMIN
   fi
   if [ ! -z "$ORACLE_TRANSACTIONS" ] ; then
     echo "alter system set transactions=$ORACLE_TRANSACTIONS scope=$ORACLE_PROCESS_SCOPE;" | $SQL_PLUS_COMMAND_ADMIN
   fi

	echo "true" > "$ORACLE_RESTART_FILE"
}

if [ ! -z "$ORACLE_PROCESS" ] ; then
  if [[ "$ORACLE_FORCE_PROCESS" == "true" || ! -e "$FILE_SET_PROCESS_SYSTEM" ]]; then
     setProcess
  elif [[ -e "$FILE_SET_PROCESS_SYSTEM" && "$( cat $FILE_SET_PROCESS_SYSTEM )" != "$ORACLE_PROCESS" ]]; then
     setProcess
  fi	
fi











