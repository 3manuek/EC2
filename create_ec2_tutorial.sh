#!/bin/bash

# How many instances per region? Total?

# Preset `aws configure`
# Create key pair for the machines.
# AmazonEC2FullAccess on IAM user
# Create a key pair only for the machines.
# aws ec2 create-key-pair

# Prerequisites:
#   sudo apt-get install jq
# aws cli is kinda buggy regarding the searches, so I decided to use a json
# query tool for avoid issues.


_cf=$(basename ${0})
config_file=.${_cf%.*}

source $config_file


usage() {
  #echo "Usage: $0 [-f CSV file] [-y: optimized EBS instance] [-l: list breakfixlab instances] [-r region where to find for breakfixlab instances]" 1>&2
  echo <<_EOF
    Usage: $0
      -s          Setup with configuration in $config_file
      -I          General Information over all the regions
      -D          Dry Run option
      -r          Using an specific region (mandatory for spinning hosts)

_EOF
  exit 1
}


getImage() {
  # Not working:
  #aws ec2 --region=us-west-1 describe-images --owners 984907411244  --filters "Name=tag:Name,Values=Breakfixlab_PL16"
  # need to use jq
  ar=$1
  #aws ec2 --region=${ar} describe-images --owners self  #  | jq -c '.Images[] | select(.Name | contains("$"))'
  aws ec2 --region=${ar} describe-images --owners self | \
     jq -r -c '.Images[] | [select(.Name | contains("'$IMAGE'"))] | max_by(.CreationDate) | {ImageId}[]' | head -1
}

checkKey() {
  ar=$1
   aws --region=$ar ec2 describe-key-pairs | jq -r '.KeyPairs[] | select(.KeyName | contains("'$KEY'")) | {KeyName}[]'
}

allAvailableRegions() {
    _out=$(egrep -o '[a-z]{2}-[a-z]*-[0-9]' regions.txt | uniq)
    echo $_out | xargs echo
}

initialSetup() {
  # get security groups per region, create them
  # get key pair, mandatory to provide or have one.
  # get image per region
  # store them in .db


  for ar in `allAvailableRegions | xargs echo`
  do

     [[ -z $allRegions ]] && if [ ! "$ar" == "$aws_region" ]; then
         continue
     fi

     echo Region: $ar
     echo "ImageId $(getImage $ar)"
     echo "  Generating Ansible Vars:"
     generateAnsibleVars $ar
     echo "  Generating SGs"
     generateSecurityGroupsIfNotExists $ar
     echo "  Checking KeyPairs:"
     checkKey $ar || echo "    Create the key on this region TODO: add create key"
     echo
  done

}



# Params:
# region
getInstancesInRegion() {
  ar=$1
  aws ec2 describe-instances --region ${ar} --filters "Name=tag:${tagsName},Values=${tagsValue}" \
  --query 'Reservations[*].Instances[*].[InstanceId, ImageId, PublicDnsName,Placement.AvailabilityZone, State.Name, InstanceType ]' \
  --output table | sed -E '/((-){10,}|DescribeInstances)|^$/d' | tr "|" "," | xargs echo | sed -e 's/^,//'
}

updateList() {
  # Update Host list and exit
  cat /dev/null > $INSTANCE_OUT
  for ar in $(egrep -o '[a-z]{2}-[a-z]*-[0-9]' regions.txt | uniq)
  do
    instancesRow=$(aws ec2 describe-instances --region ${ar} --filters "Name=tag:${tagsName},Values=${tagsValue}" \
                  --query 'Reservations[*].Instances[*].[InstanceId, ImageId, PublicDnsName, Placement.AvailabilityZone, State.Name,  InstanceType]' \
                  --output table | sed -E '/((-){10,}|DescribeInstances)|^$/d' | tr "|" "," | xargs echo | sed -e 's/^,//' | sed '/^$/d')
    [[ -z $instancesRow ]] || instancesRow="$instancesRow $(getSecurityGroups $ar)"
    [[ -z $instancesRow ]] || echo $instancesRow >> ${INSTANCE_OUT}

    #grep instance ${INSTANCE_OUT} | awk '{print $3}' | while read line; do
    #  aws ec2 describe-instances ${line} --region ${aws_region} | grep INSTANCE |awk '{print "ID:", $2, "Region:", $11, "Instance type:", $9, "IP:", $14, "Public DNS:", $4}'
    #done
  done

  [[ exitAfterUpdate ]] && exit 0
}

stopAllTheInstancesAcrossAllRegions() {
  # Go trhough all the regions and stop all the instances with `aws ec2 stop-instance`
  echo
}

getSecurityGroups() {
  ar=$1
  aws ec2 --region=${ar} describe-security-groups \
      --group-names $tagsName --query 'SecurityGroups[]' 2> /dev/null | \
      jq -r '.[] | {GroupId}[]'
}

addInstances() {
  # $dry_run
  #count instances in region, add numberAddHostsPerRegion
  [ ! -z "$allRegions" ] && {
    # All regions
    echo
  } || {
    # just aws_region
    echo
  }


}

generateKeyPair() {
  echo
}

generateSecurityGroupsIfNotExists() {
  ar=$1
  _SECGROUP=$(aws ec2 --region=$ar $dry_run create-security-group --group-name $tagsName --description "${tagsValue}" 2>/dev/null | jq -r ' {GroupId}[]')
  [[ ( $? -eq 0 || $? -eq 255 )]] || { echo "You don't have permissions to create SG in AWS with your account" ; [[ ! -z $dry_run ]] && exit 100 ; }

  #error_code=$(aws ec2 --region=$ar create-security-group --group-name $tagsName --description "${tagsValue}" 2>/dev/null || echo $?)
  error_code=$(aws ec2 --region=$ar  $dry_run authorize-security-group-ingress --group-name $tagsName --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || echo $?)
  [[ ( $error_code == 0 ) || ( $error_code == 255 )  ]] || { echo "You don't have permissions to create SG in AWS with your account" ; [[ ! -z $dry_run ]] && exit 100 ; }
  [[ ! -z $_SECGROUP ]] && echo "Created SG ${_SECGROUP} on ${ar}."

}

# Per region
generateAnsibleVars() {
  ar=$1
  currentInstances=$(grep -c "$1" $INSTANCE_OUT)
  [[ ! -z $numInstancesRegionArg ]] && { numAddFromCurrent=$((numInstancesRegionArg - currentInstances)) ;  }
  [[ $numAddFromCurrent -lt 1 ]] && numAddFromCurrent=1
  echo "Creating $numAddFromCurrent instances. Dry Run?: ${dry_run:~no}"
  [[ ! -z $numAddFromCurrent ]] && countUp="ec2_count: $numAddFromCurrent"
  # Use the power $dry_run
  SECGROUP=$(aws ec2 --region=${ar} describe-security-groups \
             --group-names $tagsName --query 'SecurityGroups[]' | \
             jq -r '.[] | {GroupId}[]' )
  cat /dev/null > ec2-vars/${tagsValue}_${ar}.yml || touch ec2-vars/${tagsValue}_${ar}.yml
  cat > ec2-vars/${tagsValue}_${ar}.yml <<_EOF
ec2_keypair: "${KEY}"
ec2_security_group: "${SECGROUP}"
ec2_instance_type: "${INSTANCE_SIZE}"
ec2_image: "${IMAGE}"

ec2_region: "${ar}"
ec2_tag_Name: "${tagsValue}"
ec2_tag_Type: "${tagsValue}"
ec2_tag_Environment: "${tagsValue}"
${countUp}
_EOF

# Cowardly doing nasty comments:
# ec2_subnet_ids: ['subnet-REDACTED','subnet-REDACTED','subnet-REDACTED']
# ec2_volume_size: 16
}



## generalInformation
generalInformation() {
  for ar in `allAvailableRegions`
  do
    echo "Region $ar"
    AMI=$(getImage $ar)
    [[ -z $AMI ]] && echo "AMI not present " || echo "ImageId $AMI"

    getInstancesInRegion $ar
    getSecurityGroups $ar
  done
}


#######################################################
#
# Main
#
#
#######################################################


## Prerequisites

prerequisites="jq"

for preq in $prerequisites
do
  hash $preq 2>/dev/null || { echo >&2 "I require $preq but it's not installed."; exit 404; }
done



## Options

while getopts "f:a:ylr:n:DsIyhu:USa:" o; do
    case "${o}" in
        f)
            f=${OPTARG}
            ;;
        a)
            numberAddHostsPerRegion=${OPTARG}
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
        n)
            numInstancesRegionArg=${OPTARG}
            ;;
        D)
            dry_run=" --dry-run "
            ;;
        s)
            initialSetup $aws_region
            ;;
        I)
            generalInformation
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
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

[ -z "$aws_region" ] && allRegions=1
