#!/bin/bash

function error_exit() {
  echo "$1" 1>&2
  exit 1
}

function check_deps() {
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

function parse_input() {
  eval "$(jq -r '@sh "export LISTENER_ARN=\(.listener_arn) EB_HOSTNAME=\(.eb_hostname)"')"
  if [[ -z "${LISTENER_ARN}" ]]; then export LISTENER_ARN=none; fi
  if [[ -z "${EB_HOSTNAME}" ]]; then export EB_HOSTNAME=none; fi
}

function modify_rules() {
  RULE_LIST=$(aws elbv2 describe-rules --listener-arn ${LISTENER_ARN} | jq -r '.Rules[] | select(.Conditions[].Values[0]=="'${EB_HOSTNAME}'") | .RuleArn' )
  for rule_arn in ${RULE_LIST}; do
    RESULT=$(aws elbv2 modify-rule --rule-arn $rule_arn --actions file://actions-fixed-response.json)
  done

  jq -n \
    --arg rule_arn "$rule_arn" \
    '{"arn":$rule_arn}'
}

check_deps
check_deps
parse_input
modify_rules