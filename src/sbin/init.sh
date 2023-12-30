#!/bin/bash
set -o errexit

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
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

# restore positional parameters
set -- "${POSITIONAL[@]}"

echo "Running init scripts ..."

log() {
  LOG="${1}"
  echo $(date +"%Y-%m-%d %H:%M:%S.%3N") - $LOG
}

source "/usr/sbin/sqlplus.sh"

SQL_PLUS_CREDENTIALS_FILE="${SQL_PLUS_CREDENTIALS:-sql-plus-credentials}"

runFolderScripts(){

  _FOLDER_SCRIPTS="${1}"  
  _array=($(find "$_FOLDER_SCRIPTS" -maxdepth 1 -type f -name *.sql | sort ))
  _array_scripts=($(find "$_FOLDER_SCRIPTS" -maxdepth 1 -type f -name '*.sh' ))   
  for _file_sql in ${_array[@]} 
  do        
     log "Rodando SQL - $( basename $_file_sql) Usuario:$ORACLE_USER_SYSTEM"
     _file_sql_tmp="$(mktemp)"
     envsubst < "$_file_sql" > "$_file_sql_tmp"
     find $_file_sql_tmp -type f  -exec sh -c 'tr -d "\r" < "{}" > "{}".new && mv "{}".new "{}"' -- {} \; -exec chmod +x {} \;

     for _script in ${_array_scripts[@]} 
     do        
        echo "Executando arquivo $_file_sql_tmp em $_script"
        eval "$_script" "$_file_sql_tmp"
        echo ""
     done

     _SQL_PLUS_CREDENTIALS="$SQL_PLUS_CREDENCIAIS_ADMIN"
     SQL_PLUS_CREDENTIALS="$(dirname $_file_sql)/$SQL_PLUS_CREDENTIALS_FILE"
     if [ -f "$SQL_PLUS_CREDENTIALS" ] ; then     
       _SQL_PLUS_CREDENTIALS="$(envsubst < $SQL_PLUS_CREDENTIALS)"
       echo "Nova credenciail:$SQL_PLUS_CREDENTIALS"
     fi 

 
     #echo "exit" | $_SQL_PLUS_COMMAND @"$_file_sql_tmp"
     sqlplus -s /nolog << EOF

      CONNECT $_SQL_PLUS_CREDENTIALS;

      whenever sqlerror exit sql.sqlcode;

      set echo off 
      set heading off

      @$_file_sql_tmp;

      exit;

EOF
     log "SQL $( basename $_file_sql) executada com sucesso."
     echo ""
  done    

}

echo "Arquivos startup."

find "$FOLDER_INIT_DB" -type f || echo ''

_array_folders=($(find "$FOLDER_INIT_DB" -mindepth 1 -type d | sort ))   

if [ -z "$_array_folders" ] ; then
	 _array_folders=("$FOLDER_INIT_DB")
fi

for _folder_sql in ${_array_folders[@]} 
do           
    runFolderScripts "$_folder_sql"
done    

echo "Init executado."
