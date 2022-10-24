#!/bin/bash

MY_DIR="$(dirname "$0")"

set -e
set -o xtrace

POSITIONAL=()

ALIAS="investments"
DAYS=7
DEFINITION="config/project-scratch-def.json"

while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
  -s | --targetsourceusername)
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

SOURCE_QUERY="SELECT Id, ApexTestRunResultId, TestTimestamp, RunTime, ApexClass.Name, MethodName FROM ApexTestResult"
if [[ -z $RUN_ID ]]; then
    echo "Getting All Completed Test Results"
    SOURCE_QUERY="$SOURCE_QUERY WHERE ApexTestRunResult.Status = 'Completed'"
else
    echo "Getting Test Results for Job Id $RUN_ID"
    SOURCE_QUERY="$SOURCE_QUERY WHERE ApexTestRunResultId = '$RUN_ID'"
fi;
SOURCE_CMD="sfdx force:data:soql:query --query=\"$SOURCE_QUERY\" --resultformat=csv"
if [[ -z $FROM_ORG ]]; then
    echo "Getting Test Results from project default org"
else
    echo "Getting Test Results from $FROM_ORG"
    SOURCE_CMD="$SOURCE_CMD --targetusername=$FROM_ORG"
fi;

eval $SOURCE_CMD > test-result.csv

tail -n+2 test-result.csv > test-result2.csv
echo -e "TestResultId__c,TestRunId__c,RunDate__c,RunTime__c,ClassName__c,MethodName__c\n$(cat test-result2.csv)" > test-result3.csv

if [[ -z $TO_ORG ]]; then
    echo "Uploading Test Results to project default org"
    sfdx force:data:bulk:upsert --sobjecttype TestResult__c --csvfile test-result3.csv --externalid TestResultId__c
else
    echo "Uploading Test Results to $TO_ORG"
    sfdx force:data:bulk:upsert --sobjecttype TestResult__c --csvfile test-result3.csv --externalid TestResultId__c --targetusername=$TO_ORG
fi;