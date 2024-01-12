#!/bin/bash
set -o errexit

POSITIONAL=()
PARAMS=()
PARAMS+=( $@ )

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in                     
      -v|--verbose)
      set -x
      VERBOSE="${1}"
      shift # past argument      
      ;;
      --users-envs-prefix)
      ORACLE_USERS_PREFIX_ENVS="${2}"
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

_USER_ENVS_NAMES=( $( printf '%s ' $(sh -c "env | cut -d'=' -f1" | grep -e "${ORACLE_USERS_PREFIX_ENVS}_.*_LOGIN$" ) ) )
for _USER_ENV_NAME in ${_USER_ENVS_NAMES[@]} 
do
    _USER_ENV_VALUE="$(echo $_USER_ENV_NAME | awk -F '_LOGIN' '{print $1}'  )"
    $FOLDER_ORACLE_SCRIPTS/oracle-create-user.sh ${PARAMS[@]} --prefix-key "$_USER_ENV_VALUE"
done