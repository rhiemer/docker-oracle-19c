#!/bin/bash
set -o errexit

POSITIONAL=()
while [[ $# -gt 0 ]]
 do
   key="$1"
   case $key in
      -v|--verbose)
      VERBOSE="${1}"
      set -x
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
 
source "$FOLDER_ORACLE_SCRIPTS/sqlplus.sh"

echo "Performing initial database setup ..."

FILE_SQL=$(mktemp -t)

COMMAND=()
COMMAND+=($FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} -f )

if [ "$RELAX_SECURITY" == "true" ]; then
	echo "WARNING: Relaxing profile security with no password reuse limits, etc. Use with caution ..."
	echo "CREATE PROFILE NOEXPIRY LIMIT COMPOSITE_LIMIT UNLIMITED PASSWORD_LIFE_TIME UNLIMITED PASSWORD_REUSE_TIME UNLIMITED PASSWORD_REUSE_MAX UNLIMITED PASSWORD_VERIFY_FUNCTION NULL PASSWORD_LOCK_TIME UNLIMITED PASSWORD_GRACE_TIME UNLIMITED FAILED_LOGIN_ATTEMPTS UNLIMITED;" | ${COMMAND[@]} --connect "$SQL_PLUS_CREDENCIAIS_PWD_SYSDBA"
    
	echo "ALTER USER $ORACLE_USER PROFILE NOEXPIRY;" | ${COMMAND[@]} --connect "$SQL_PLUS_CREDENCIAIS_PWD_SYSDBA"
	echo "ALTER USER $ORACLE_USER_SYSTEM PROFILE NOEXPIRY;" | ${COMMAND[@]} --connect "$SQL_PLUS_CREDENCIAIS_PWD_SYSDBA" 
	echo "Security relaxed."	
fi

if [ ! -z "$ORACLE_USER_SYSTEM_PASSWORD" ] ; then
	echo "Setting $ORACLE_USER_SYSTEM password... "
	echo "ALTER USER $ORACLE_USER_SYSTEM IDENTIFIED BY \"$ORACLE_USER_SYSTEM_PASSWORD\";" | ${COMMAND[@]}  --connect "$SQL_PLUS_CREDENCIAIS_PWD_SYSDBA"
fi

if [ "$ALLOW_REMOTE" == "true" ]; then
  echo "System disable restricted session... "
  echo "alter system disable restricted session;" | ${COMMAND[@]}  --connect "$SQL_PLUS_CREDENCIAIS_PWD_SYSDBA"
fi

if [ ! -z "${ORACLE_USER_PASSWORD// }" ]; then
	echo "Setting $ORACLE_USER password... "
	echo "ALTER USER $ORACLE_USER IDENTIFIED BY \"$ORACLE_USER_PASSWORD\";" | ${COMMAND[@]} --connect "$SQL_PLUS_CREDENCIAIS_PWD_SYSDBA"
fi







