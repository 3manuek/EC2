#!/bin/bash
# Description: This script is used to launch EC2 instances, you must  provide a csv file with this fields:
#               AMI,I_TYPE,ZONE,ENV,NAME
# Requirements: This user needs a global variable environment with ec2 keys
# Author: Narcis pillao - npillao@blackbirdit.com
# Modified By: Alkin Tezuysal - atezuysal@blackbirdit.com


INSTANCE_OUT="/tmp/instance_output.$$"
OLDIFS=$IFS
IFS=,

optimized=''
aws_region='us-west-2'
list=0
tag_service=mysql
description="breakfixlab"

## Get prompt variables
usage() { echo "Usage: $0 [-f CSV file] [-y: optimized EBS instance] [-l: list breakfixlab instances] [-r region where to find for breakfixlab instances]" 1>&2; exit 1; }


while getopts "f:nlr:" o; do
    case "${o}" in
        f)
            f=${OPTARG}
            ;;
        y)
            optimized='--ebs-optimized'
            ;;
        l)
            list=1
            ;;
        r)
            aws_region=${OPTARG}
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

FILE_SRC=${f}

if [[ ${list} == 1 ]]; then
  echo "Looking for breakfixlab instances on region: ${aws_region}"
  echo
  ec2-describe-tags --region ${aws_region} --filter "key=Description" --filter "value=${description}" > ${INSTANCE_OUT}
  grep instance ${INSTANCE_OUT} | awk '{print $3}' |while read line; do
   ec2-describe-instances ${line} --region ${aws_region} |grep INSTANCE |awk '{print "ID:", $2, "Region:", $11, "Instance type:", $9, "IP:", $14, "Public DNS:", $4}'
  done
  echo
  echo "Done"
  rm ${INSTANCE_OUT}
  exit 0
fi


[ -z $FILE_SRC ] && { echo "Error: You have to pass the CSV file name"; exit 2; }
[ ! -f $FILE_SRC ] && { echo "Error: This file does not exist"; exit 2; }



while read AMI_ID IN_TYPE REGION NAME KEY; do

  [[ ${REGION} == 'us-west-2' ]] &&  s_group=sg-fabc78c9
  [[ ${REGION} == 'us-west-1' ]] &&  s_group=sg-3858d17c
  [[ ${REGION} == 'us-east-1' ]] &&  s_group=sg-c6fdb3ac
  [[ ${REGION} == 'eu-west-1' ]] &&  s_group=sg-4faaac38

  ec2-run-instances ${AMI_ID} -t ${IN_TYPE} ${optimized} --region  ${REGION} -g ${s_group} -k ${KEY} -b "/dev/sdc=ephemeral0" -b "/dev/sdd=ephemeral1" > ${INSTANCE_OUT}
  sleep 3
  resource_id=`grep INSTANCE ${INSTANCE_OUT} | awk '{print $2}'`
  get_dns=`ec2-describe-instances ${resource_id} --region ${REGION} |grep INSTANCE | awk '{print $4}'`
  ec2-create-tags  ${resource_id} --region ${REGION} --tag "Name=${NAME}-${resource_id}" --tag "Service=${tag_service}" --tag "Description=${description}" > /dev/null
  echo "Instance ${NAME}-${resource_id} has DNS entry: ${get_dns}"

done < $FILE_SRC
IFS=$OLDIFS
