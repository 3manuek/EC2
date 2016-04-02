#!/bin/bash

# How many instances per region? Total?

# Preset `aws configure`
# Create key pair for the machines.
# AmazonEC2FullAccess on IAM user
# Create a key pair only for the machines.
# aws ec2 create-key-pair

tag_service=mysql
description="breakfixlab"
# INSTANCE_OUT="/tmp/instance_output.$$"
INSTANCE_OUT=".db"
KEY=breakfixlab


usage() {
  echo "Usage: $0 [-f CSV file] [-y: optimized EBS instance] [-l: list breakfixlab instances] [-r region where to find for breakfixlab instances]" 1>&2
  exit 1
}

updateList() {
  # Update Host list and exit
  cat /dev/null > $INSTANCE_OUT
  for aws_region in $(egrep -o '[a-z]{2}-[a-z]*-[0-9]' regions.txt | uniq)
  do

    #aws ec2 describe-instances --region us-west-1 \
    # --filters 'Name=tag:mysql,Values=breakfixlab' \
    # --query 'Reservations[].Instances[].Tags[].Value'



    echo aws ec2 describe-tags --region ${aws_region} --filters "key=description,Values=${description}" >> ${INSTANCE_OUT}
    #grep instance ${INSTANCE_OUT} | awk '{print $3}' | while read line; do
    #  aws ec2 describe-instances ${line} --region ${aws_region} | grep INSTANCE |awk '{print "ID:", $2, "Region:", $11, "Instance type:", $9, "IP:", $14, "Public DNS:", $4}'
    #done
  done
  [[ exitAfterUpdate ]] && exit 0
}

stopAllTheInstancesAcrossAllRegions() {
  # Go trhough all the regions and stop all the instances with `aws ec2 stop-instance`
}

addInstances() {
  #count instances in region, add numberAddHostsPerRegion

}



while getopts "f:ylr:hu:USa:" o; do
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
        u)
            updateList
            ;;
        U)
            exitAfterUpdate=1
            updateList
            ;;
        S)
            stopAllTheInstancesAcrossAllRegions
            ;;
        a)
            numberAddHostsPerRegion=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
