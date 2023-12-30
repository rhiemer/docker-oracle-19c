#!/bin/bash

set -o errexit

PARAMS=()
PARAMS+=( $@ )

PARAMS_BUILD_PUSH_LOCAL=()
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
      -c)
      COMMAND=${2}
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

${COMMAND[@]}