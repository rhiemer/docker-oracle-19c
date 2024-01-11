#!/bin/bash
set -o errexit

POSITIONAL=()
SCHEMAS=()

while [[ $# -gt 0 ]]
 do
   key="$1"
   case $key in
      -v|--verbose)
      set -x
      VERBOSE="${1}"
      shift # past argument      
      ;;
      --oracle-credentials)
      ORACLE_CREDENTIALS="${2}"
      shift # past argument
      shift # past argument
      ;;
      --users-envs-prefix)
      ORACLE_USERS_PREFIX_ENVS="${2}"
      shift # past argument      
      shift # past argument      
      ;;
      --prefix-key)
      PREFIX_KEY="${2}"
      shift # past argument
      shift # past argument
      ;;      
      --user-name-envs)
      USER_NAME_ENVS="${2}"
      shift # past argument
      shift # past argument
      ;;      
      --user-recreate)
      USER_RECREATE="${2}"
      shift # past argument
      shift # past argument
      ;; 
      --create-table-space)
      CREATE_TABLE_SPACE="${2}"
      shift # past argument
      shift # past argument
      ;;      
      --table-space-params)
      RESTORE_TABLESPACE_PARAMS="${2}"
      shift # past argument
      shift # past argument
      ;;
      --table-space-recreate)
      TABLESPACE_RECREATE="${2}"
      shift # past argument
      shift # past argument
      ;; 
      --role-name)
      ROLE_NAME="${2}"
      shift # past argument
      shift # past argument
      ;;
      --enable-xa)
      ENABLED_XA_LOCAL="${2}"
      shift # past argument
      shift # past argument
      ;;
      --all-tablespaces)
      ALL_TABLES_SPACES="${2}"
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

source "$FOLDER_ORACLE_SCRIPTS/sqlplus.sh"
source "$FOLDER_ORACLE_SCRIPTS/functions.sh"

createAndSetRoleUser(){
  ROLE_NAME_KEY="${PREFIX_KEY}_ROLE_NAME"
  _ROLE_NAME="${!ROLE_NAME_KEY}"
  ROLE_NAME="${_ROLE_NAME:-$ROLE_NAME}"
  if [  ! -z "${ROLE_NAME// }" ]; then  
    createRoleFactory "$ROLE_NAME" || echo "Não foi possível criar a role $ROLE_NAME."
    setRoleUser "$_USER_SCHEMA_NAME" "$ROLE_NAME"
  fi
}

setUserXa(){
  ENABLED_XA_KEY="${PREFIX_KEY}_ENABLE_XA"
  _ENABLED_XA="${!ENABLED_XA_KEY:-$ENABLED_XA_LOCAL}"
  _ENABLED_XA="${_ENABLED_XA:-$ORACLE_ENABLE_XA_USER_DEFAULT}"
  _ENABLED_XA="${_ENABLED_XA:false}"
  if [[ "$_ENABLED_XA" == "true" ]]; then
    echo "Habilitando o usuário $_USER_SCHEMA_NAME para XA."
    echo ""
    enableXAOracle "$_USER_SCHEMA_NAME"
  fi
}

setUserAllTableSpaces(){
  ALL_TABLESPACES_KEY="${PREFIX_KEY}_ALL_TABLESPACES"
  _ALL_TABLESPACES="${!ALL_TABLESPACES_KEY:-$ALL_TABLES_SPACES}"
  _ALL_TABLESPACES="${_ENABLED_XA:-$ORACLE_ENABLE_XA_USER_DEFAULT}"
  _ENABLED_XA="${_ENABLED_XA:false}"
  if [[ "$_ENABLED_XA" == "true" ]]; then
    echo "Habilitando o usuário $_USER_SCHEMA_NAME para XA."
    echo ""
    enableXAOracle "$_USER_SCHEMA_NAME"
  fi
}

compUsuario(){
  changePasswordUserOracle "$_USER_SCHEMA_NAME" "$_USER_SCHEMA_NAME_PASSWORD"
  setUserXa
  createAndSetRoleUser
}

USER_NAME_ENVS="${USER_NAME_ENVS^^}" 
PREFIX_KEY_DEFAULT="${ORACLE_USERS_PREFIX_ENVS}_${USER_NAME_ENVS}"
PREFIX_KEY="${PREFIX_KEY:-$PREFIX_KEY_DEFAULT}"

_USER_SCHEMA_NAME_KEY="${PREFIX_KEY}_LOGIN"
_USER_SCHEMA_NAME="${!_USER_SCHEMA_NAME_KEY:-$USER_NAME_ENVS}"

USER_RECREATE_KEY="${PREFIX_KEY}_USER_RECREATE"
_USER_RECREATE="${!USER_RECREATE_KEY}"
USER_RECREATE="${_USER_RECREATE:-$USER_RECREATE}"

_USER_SCHEMA_NAME_PASSWORD_KEY="${PREFIX_KEY}_PASSWORD"
_USER_SCHEMA_NAME_PASSWORD="${!_USER_SCHEMA_NAME_PASSWORD_KEY}"

if [[ "$USER_RECREATE" == "true" ]]; then  
  dropUser "$_USER_SCHEMA_NAME" || echo "Não foi possível dropar o usuário $_USER_SCHEMA_NAME"
else
  userExists "$_USER_SCHEMA_NAME"
  if [[ "$P_USER_CREATE" == "true" ]]; then
    echo "Usuário já criado $_USER_SCHEMA_NAME"
    compUsuario;
    exit 0;
  fi
fi  

TABLESPACE_NAME_KEY="${PREFIX_KEY}_TABLESPACE_NAME"
CREATE_TABLE_SPACE_KEY="${PREFIX_KEY}_TABLESPACE_CREATE"
_CREATE_TABLE_SPACE="${!CREATE_TABLE_SPACE_KEY}"
CREATE_TABLE_SPACE="${_CREATE_TABLE_SPACE:-$CREATE_TABLE_SPACE}"

TABLESPACE_NAME_DEFAULT="$ORACLE_TABLE_SPACE_DEFAULT"
if [[ "$CREATE_TABLE_SPACE" == "true" ]]; then  
  TABLESPACE_NAME_DEFAULT="TS_${_USER_SCHEMA_NAME^^}"
fi
TABLESPACE_NAME="${!TABLESPACE_NAME_KEY:-$TABLESPACE_NAME_DEFAULT}"

if [[ "$CREATE_TABLE_SPACE" == "true" ]]; then
  TABLESPACE_RECREATE_KEY="${PREFIX_KEY}_TABLESPACE_RECREATE"
  _TABLESPACE_RECREATE="${!TABLESPACE_RECREATE_KEY}"
  TABLESPACE_RECREATE="${_TABLESPACE_RECREATE:-$TABLESPACE_RECREATE}"
  TABLESPACE_RECREATE="${TABLESPACE_RECREATE:-true}"

  if [[ "$TABLESPACE_RECREATE" == "true" ]]; then  
    dropTableSpace "$TABLESPACE_NAME" || echo "Não foi possível dropar a tablespace $TABLESPACE_NAME"
  fi  

  TABLESPACE_FILE_KEY="${PREFIX_KEY}_TABLESPACE_FILE"
  TABLESPACE_FILE="${!TABLESPACE_FILE_KEY}"
  TABLESPACE_PARAMS_KEY="${PREFIX_KEY}_TABLESPACE_PARAMS"
  TABLESPACE_PARAMS="${!TABLESPACE_PARAMS_KEY}"

  createTableSpace "$TABLESPACE_NAME" "$TABLESPACE_FILE" "$TABLESPACE_PARAMS"

fi


createUserOracle "$_USER_SCHEMA_NAME" "$TABLESPACE_NAME" "$_USER_SCHEMA_NAME_PASSWORD"
compUsuario;
