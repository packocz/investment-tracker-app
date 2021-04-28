#!/bin/bash

MY_DIR="$(dirname "$0")"

set -e

POSITIONAL=()

ALIAS="investments"
DAYS=7
DEFINITION="config/project-scratch-def.json"

while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
  -a | --setalias)
    ALIAS="$2"
    shift
    shift
    ;;
  -d | --durationdays)
    DAYS="$2"
    shift
    shift
    ;;
  -v | --targetdevhubusername)
    DEVHUB="$2"
    shift
    shift
    ;;
  -f | --definitionfile)
    DEFINITION="$2"
    shift
    shift
    ;;
  *) # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
  esac
done

if [[ -z $DEVHUB ]]; then
    echo "creating org with alias $ALIAS for $DAYS days using $DEFINITION defition file in default DevHub"
    sfdx force:org:create -f $DEFINITION -a $ALIAS -d $DAYS -s
else
    echo "creating org with alias $ALIAS for $DAYS days using $DEFINITION defition file in DevHub $DEVHUB"
    sfdx force:org:create -f $DEFINITION -a $ALIAS -d $DAYS -s -v $DEVHUB
fi;

echo "pushing source"
sfdx force:source:push
echo "assigning permset"
sfdx force:user:permset:assign --permsetname=InvestmentTracker
echo "pushing data"
sfdx texei:data:import -d data/example