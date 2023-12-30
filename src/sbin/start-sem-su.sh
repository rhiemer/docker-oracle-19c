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

touch /lib/lsb/init-functions
echo "export SU=/usr/sbin/su.sh" >> /lib/lsb/init-functions