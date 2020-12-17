#!/bin/bash

function error_exit() {
  echo "$1" 1>&2
  exit 1
}

function check_deps() {
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

function parse_input() {
  eval "$(jq -r '@sh "export LB_ARN=\(.lb_arn) EB_NAME=\(.eb_name)"')"
  if [[ -z "${LB_ARN}" ]]; then export LB_ARN=none; fi
  if [[ -z "${EB_NAME}" ]]; then export EB_NAME=none; fi
}

function return_token() {
  TG_LIST=$(aws elbv2 describe-target-groups --load-balancer-arn ${LB_ARN} | jq -r '.TargetGroups[].TargetGroupArn' )
  for tg_arn in ${TG_LIST}; do
    MATCH=$(aws elbv2 describe-tags --resource-arn ${tg_arn} | jq -r '.TagDescriptions[].Tags[] | select((.Key=="elasticbeanstalk:environment-name") and .Value=="'${EB_NAME}'")' )
    if [[ -n "${MATCH}" ]]; then 
      export TG_ARN=$tg_arn;
    fi
  done

  jq -n \
    --arg tg_arn "$TG_ARN" \
    '{"arn":$tg_arn}'
}

check_deps
check_deps
parse_input
return_token