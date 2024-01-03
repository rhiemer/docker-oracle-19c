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
 
source "/usr/sbin/sqlplus.sh"

echo "Performing initial database setup ..."

if [ "$RELAX_SECURITY" == "true" ]; then
	echo "WARNING: Relaxing profile security with no password reuse limits, etc. Use with caution ..."
	echo "CREATE PROFILE NOEXPIRY LIMIT
			COMPOSITE_LIMIT UNLIMITED
			PASSWORD_LIFE_TIME UNLIMITED
			PASSWORD_REUSE_TIME UNLIMITED
			PASSWORD_REUSE_MAX UNLIMITED
			PASSWORD_VERIFY_FUNCTION NULL
			PASSWORD_LOCK_TIME UNLIMITED
			PASSWORD_GRACE_TIME UNLIMITED
			FAILED_LOGIN_ATTEMPTS UNLIMITED;" | $SQL_PLUS_COMMAND_ADMIN
			
	echo "ALTER USER SYSTEM PROFILE NOEXPIRY;" | $SQL_PLUS_COMMAND_ADMIN
	echo "ALTER USER SYS PROFILE NOEXPIRY;" | $SQL_PLUS_COMMAND_ADMIN
	echo "Security relaxed."
	
fi


_ORACLE_PASSWORD="${ORACLE_PASSWORD:-$ORACLE_PWD}"
if [ ! -z "${_ORACLE_PASSWORD// }" ]; then
	echo "Setting SYS password... "
	if ! echo "ALTER USER SYS IDENTIFIED BY \"$_ORACLE_PASSWORD\";" | $SQL_PLUS_COMMAND_ADMIN ; then
		echo "Error setting SYS password."
		exit 1;
	fi
fi

_ORACLE_USER_SYSTEM_PASSWORD="${ORACLE_USER_SYSTEM_PASSWORD:-$ORACLE_PWD}"
if [ ! -z "$_ORACLE_USER_SYSTEM_PASSWORD" ] ; then	
	echo "Setting SYSTEM password... "
	if	! echo "ALTER USER SYSTEM IDENTIFIED BY \"$ORACLE_USER_SYSTEM_PASSWORD\";" | $SQL_PLUS_COMMAND_ADMIN  ; then
		echo "Error setting SYSTEM password."
		exit 1;
	fi
fi

_ORACLE_PDBADMIN_PASSWORD="${ORACLE_PDBADMIN_PASSWORD:-$ORACLE_PWD}"
if [ ! -z "$_ORACLE_PDBADMIN_PASSWORD" ] ; then	
	echo "Setting PDBADMIN password... "
	if	! echo "ALTER USER PDBADMIN IDENTIFIED BY \"$_ORACLE_PDBADMIN_PASSWORD\";" | $SQL_PLUS_COMMAND_ADMIN  ; then
		echo "Error setting PDBADMIN password."
		exit 1;
	fi
fi

if [ "$ALLOW_REMOTE" == "true" ]; then
  echo "alter system disable restricted session;" | $SQL_PLUS_COMMAND_ADMIN
fi





