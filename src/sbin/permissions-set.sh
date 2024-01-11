#!/bin/bash
set -o errexit

POSITIONAL=()
FILES_PERMISSIONS=()
ACTIONS=()
ACTIONS_COMP=()


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
      --actions)
      ACTIONS+=("${2}")
      shift # past argument
      shift # past argument
      ;;
      --action-comp)
      ACTIONS_COMP+=("${2}")
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

for FILE_PERMISSIONS in ${FILES_PERMISSIONS[@]} 
do
  for ACTION in ${ACTIONS[@]} 
    awk "{print \"$ACTION ${ACTIONS_COMP[@]}\" \$0 \" TO $TO\"}" $FILE_PERMISSIONS 
  done 
done
