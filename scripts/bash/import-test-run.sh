#!/bin/bash

MY_DIR="$(dirname "$0")"

set -e
set -o xtrace

POSITIONAL=()

while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
  -s | --sourceusername)
    FROM_ORG="$2"
    shift
    shift
    ;;
  -u | --targetusername)
    TO_ORG="$2"
    shift
    shift
    ;;
  -r | --testrunid)
    RUN_ID="$2"
    shift
    shift
    ;;
  *) # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
  esac
done

SOURCE_QUERY="SELECT Id, StartTime, EndTime, TestTime, MethodsCompleted, ClassesCompleted FROM ApexTestRunResult"
if [[ -z $RUN_ID ]]; then
    echo "Getting All Completed Test Run Results"
    SOURCE_QUERY="$SOURCE_QUERY WHERE Status = 'Completed'"
else
    echo "Getting Test Run Results for Job Id $RUN_ID"
    SOURCE_QUERY="$SOURCE_QUERY WHERE AsyncApexJobId = '$RUN_ID'"
fi;
SOURCE_CMD="sfdx force:data:soql:query --query=\"$SOURCE_QUERY\" --resultformat=csv"
if [[ -z $FROM_ORG ]]; then
    echo "Getting Test Run Results from project default org"
else
    echo "Getting Test Run Results from $FROM_ORG"
    SOURCE_CMD="$SOURCE_CMD --targetusername=$FROM_ORG"
fi;

eval $SOURCE_CMD > run-result.csv

tail -n+2 run-result.csv > run-result2.csv
echo -e "TestRunId__c,StartTime__c,EndTime__c,TestTime__c,NumberOfMethods__c,NumberOfClasses__c\n$(cat run-result2.csv)" > run-result3.csv

if [[ -z $TO_ORG ]]; then
    echo "Uploading Test Run Results to project default org"
    sfdx force:data:bulk:upsert --sobjecttype TestRun__c --csvfile run-result3.csv --externalid TestRunId__c
else
    echo "Uploading Test Run Results to $TO_ORG"
    sfdx force:data:bulk:upsert --sobjecttype TestRun__c --csvfile run-result3.csv --externalid TestRunId__c --targetusername=$TO_ORG
fi;