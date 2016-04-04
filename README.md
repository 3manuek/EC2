Usage: ./create_aws_instances.sh [-f CSV file] [-y: optimized EBS instance] [-l: list breakfixlab instances] [-r region where to find for breakfixlab instances]


Desirable in the future, ansible setup https://github.com/adenot/blog-ansible-provision-ec2

# HOWTO

## Configuration

Please check variables in `.create_ec2_tutorial`.

## SecurityGroups

Run:

```
./create_ec2_tutorial.sh -s
```

## Ansible configuration

Use .boto file.

## General Information

```
./create_ec2_tutorial.sh -I
```

## Update information

```
./create_ec2_tutorial.sh -U
```

## Add instances using ansible

Add credentials in .boto


```
./create_ec2_tutorial.sh  -r us-west-1 -s -n1
./create_ec2_tutorial.sh  -r us-west-1 -a
```


## Examples

### Update list of running servers:

```
./create_ec2_tutorial.sh  -U
```

### Initial Setup


```
➜  EC2 git:(master) ✗ ./create_ec2_tutorial.sh  -r us-west-1 -s -D  -n3
Region: us-west-1
ImageId ami-2092e140
  Generating Ansible Vars:
Creating 1 instances. Dry Run?:
  Generating SGs
  Checking KeyPairs:
breakfixlab2016



```
