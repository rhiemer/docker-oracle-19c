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
      --folder-scripts)
      FOLDER_SCRIPTS="${2}"
      shift # past argument
      shift # past argument
      ;;      
      --folder-scripts-exec)
      FOLDER_SCRIPTS_EXEC="${2}"
      shift # past argument
      shift # past argument
      ;;      
      --force)
      FORCE_RUN_SQL_SYNC="${2}"
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

SQL_PLUS_CREDENTIALS_FILE="${SQL_PLUS_CREDENTIALS:-sql-plus-credentials}"
SQL_PARAMS_EXEC="${SQL_PARAMS_EXEC:-sql-params-exec}"
FORCE_RUN_SQL_SYNC="${FORCE_RUN_SQL_SYNC:-false}"


log() {
  LOG="${1}"
  echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") - $LOG"
}


sqlCredentials(){
  _file_credential="${1}"

  _SQL_PLUS_CREDENTIALS="$SQL_PLUS_CREDENCIAIS_ADMIN"
  SQL_PLUS_CREDENTIALS="$(dirname $_file_credential)/$SQL_PLUS_CREDENTIALS_FILE"
  if [ -f "$SQL_PLUS_CREDENTIALS" ] ; then     
    _SQL_PLUS_CREDENTIALS="$(envsubst  < $SQL_PLUS_CREDENTIALS)"
  fi 
  _USER_EXEC="$( echo $_SQL_PLUS_CREDENTIALS |  awk -F '/' '{print $1}' )"
}

paramsExecSql(){
  _file_sql="${1}"
  _SQL_FILE_PARAMS_EXEC="$(dirname $_file_sql)/$SQL_PARAMS_EXEC"
  if [ -f "$_SQL_FILE_PARAMS_EXEC" ] ; then     
    _EXEC_SQL_PARAMS="$(cat $_SQL_FILE_PARAMS_EXEC)"
  else
    _EXEC_SQL_PARAMS="$(echo  $ORACLE_INIT_SQL_PARAMS)"
  fi 
}

execSql(){

  _file_sql="${1}"

  sqlCredentials "$_file_sql"
  paramsExecSql  "$_file_sql"

  _LOG="SQL - $( basename $_file_sql) Usuario:$_USER_EXEC"
  log "Executando $_LOG"
  eval $FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} --connect "$_SQL_PLUS_CREDENTIALS" --file-sql "$_file_sql" $( echo $_EXEC_SQL_PARAMS )
  log "Executado com sucesso $_LOG"
  echo ""

}

execScriptsFolder(){
  _file_exec="${1}"
  _dir_exec="$(dirname $_file_exec)"
  _array_scripts=($(find "$_dir_exec" -maxdepth 1 -type f -name '*.folder.sh' ))  
  for _script in ${_array_scripts[@]} 
  do        
    _LOG="Script Folder $( basename $_script) em $(basename $_script) "
    log "Executando $_LOG"
    eval "$_script" "$_file_exec" "${VERBOSE}"
    log "Executado com sucesso $_LOG"
    echo ""
  done
}

execScripts(){
  _file_exec="${1}"
  _LOG="Script $( basename $_file_exec)"
  log "Executando $_LOG"
  $_file_exec ${VERBOSE}
  log "Executado com sucesso $_LOG"  
  echo ""
}


execImportDump(){
  _file_dump="${1}"  
  _LOG="Importação OracleDataPump pelo arquivo $( basename $_file_dump)"
  log "Executando $_LOG ..."
  echo ""
  
  sqlCredentials "$_file_dump"

  $FOLDER_ORACLE_SCRIPTS/oracle-dump-restore-schema.sh ${VERBOSE} --oracle-credentials "$_SQL_PLUS_CREDENTIALS" --file "$_file_dump"
  log "Executado com sucesso $_LOG"  
  echo ""
}


if [[ -z "${FOLDER_SCRIPTS_EXEC// }" || ${FORCE_RUN_SQL_SYNC} == "true"  ]]; then
  _FILES_EXEC=( $( find "$FOLDER_SCRIPTS" -mindepth 1 -type f | sort ))
else
  _FILES_EXEC=( $( rsync -a --dry-run -I --checksum --out-format="xxxx:%i:/%f" "${FOLDER_SCRIPTS}/" "${FOLDER_SCRIPTS_EXEC}/" | grep 'xxxx:>' | awk -F':' '{print $3}' ))
fi

for _FILE_EXEC in ${_FILES_EXEC[@]} 
do           
  
  if [ -d "${_FILE_EXEC}" ]; then
    continue;
  fi
  

  case $_FILE_EXEC in
      *${SQL_PARAMS_EXEC}*)
      ;;
      *${SQL_PLUS_CREDENTIALS_FILE}*)
      ;;
      *${ORACLE_DATAPUMP_RESTORE_POS_PATH_NAME}*)
      ;;
      *.conf.sql)
      ;;
      *.sql)
      execSql "$_FILE_EXEC"
      ;;
      *.sh)
      execScripts "$_FILE_EXEC"
      ;;
      *.dmp)
      execImportDump "$_FILE_EXEC"
      ;;
      *)
      execScriptsFolder "$_FILE_EXEC"
      ;;
  esac

  if [  ! -z "${FOLDER_SCRIPTS_EXEC// }" ]; then
    _FILES_TARGET="${_FILE_EXEC/${FOLDER_SCRIPTS}/${FOLDER_SCRIPTS_EXEC}}"
    mkdir -p "$(dirname $_FILES_TARGET)"
    cp -rf "$_FILE_EXEC" "$_FILES_TARGET"
  fi  

done  

if [  ! -z "${FOLDER_SCRIPTS_EXEC// }" ]; then
   rsync --delete -r "${FOLDER_SCRIPTS}/" "${FOLDER_SCRIPTS_EXEC}/"
fi 


