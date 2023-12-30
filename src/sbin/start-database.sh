#!/bin/bash
set -o errexit


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

source "/usr/sbin/sqlplus.sh"


echo "Aguarando serviço do oracle iniciar."

sqlplus -s /nolog << EOF

CONNECT $ORACLE_USER/$ORACLE_USER_PASSWORD as SYSDBA;

whenever sqlerror exit sql.sqlcode;

set echo off 
set heading off

SHUTDOWN IMMEDIATE;

exit;

EOF

echo "iniciando oracle"

sqlplus -s /nolog << EOF

CONNECT $ORACLE_USER/$ORACLE_USER_PASSWORD as SYSDBA;

whenever sqlerror exit sql.sqlcode;

set echo off 
set heading off

STARTUP;
ALTER PLUGGABLE DATABASE ALL OPEN;
ALTER PLUGGABLE DATABASE ALL SAVE STATE;

exit;

EOF 



