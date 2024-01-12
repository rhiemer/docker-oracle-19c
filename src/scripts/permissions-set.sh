#!/bin/bash
set -o errexit

POSITIONAL=()
FILES_PERMISSIONS=()
ACTIONS=()

while [[ $# -gt 0 ]]
 do
   key="$1"
   case $key in
      -v|--verbose)
      set -x
      VERBOSE="${1}"
      shift # past argument      
      ;;
      --to)
      TO="${2}"
      shift # past argument
      shift # past argument
      ;;
      --file-permissions)
      FILES_PERMISSIONS+=("${2}")
      shift # past argument
      shift # past argument
      ;;
      --action)
      _ACTIONS+=("${2}")
      shift # past argument
      shift # past argument
      ;;
      --actions-comp)
      ACTIONS_COMP="${2}"
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

_COMP="${ACTIONS_COMP:+ $ACTIONS_COMP }"
for FILE_PERMISSIONS in ${FILES_PERMISSIONS[@]}
do
  
  _FILES=( $(find $FILE_PERMISSIONS -type f ) )

  for _FILE in ${_FILES[@]}
  do

      _ACTIONS=()
      _ACTIONS+=( ${ACTIONS[@]} )

      if [[ -z "${ACTIONS// }" ]]; then
        case $_FILE in
            *-create)
            _ACTIONS+=("CREATE")
            ;;
            *-alter)
            _ACTIONS+=("ALTER")
            ;;
            *-drop)
            _ACTIONS+=("DROP")
            ;;
            *-comment)
            _ACTIONS+=("COMMENT")
            ;;
            *-ddl)
            _ACTIONS+=("CREATE" "ALTER" "DROP")
            ;;
            *-select)
            _ACTIONS+=("SELECT")
            ;;
            *-insert)
            _ACTIONS+=("INSERT")
            ;;
            *-update)
            _ACTIONS+=("UPDATE")
            ;;
            *-delete)
            _ACTIONS+=("DELETE")
            ;;
            *-dml)
            _ACTIONS+=("INSERT" "UPDATE" "DELETE")
            ;;
            *-execute)
            _ACTIONS+=("EXECUTE")
            ;;
            *-flashback)
            _ACTIONS+=("FLASHBACK")
            ;;
            *-read)
            _ACTIONS+=("READ")
            ;;
            *-redifine)
            _ACTIONS+=("REDEFINE")
            ;;
            *-under)
            _ACTIONS+=("UNDER")
            ;;
            *-table)
            _ACTIONS+=("LOCK" "READ" "FLASHBACK" "REDEFINE" "UNDER" "COMMENT")
            ;;
            *-force)
            _ACTIONS+=("FORCE")
            ;;
            *-transaction)
            _ACTIONS+=("FORCE" "SELECT")
            ;;
            *-use)
            _ACTIONS+=("USE")
            ;;
            *) 
            continue;
            ;;
        esac   
      fi



      for ACTION in ${_ACTIONS[@]}
      do
        awk "{print \"GRANT $ACTION $_COMP\" \$0 \" TO $TO ; \"}" $_FILE | $FOLDER_ORACLE_SCRIPTS/output-sql-command.sh ${VERBOSE} -f --ignore-erros "true" --connect "$SQL_PLUS_COMMAND_CREDENCIAIS_SYS_SYSDBA"
      done 

  done 


done
