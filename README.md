# EC2 toolbox for tutorials

Desirable in the future, ansible setup https://github.com/adenot/blog-ansible-provision-ec2

This is a rewritten project (https://github.com/tezuysal-pythian/EC2) but with a totally different approach: more reusable, configurable and manageable. 

This project will be included in Pythian organization, whom supported this project.

Setup a _n_ number of hosts across `regions.txt` available regions.

Requires:

```
boto
jq
ansible
```

Create the key across the regions. This script will be doing this in the next release.

Be sure that your IAM user has `AmazonEC2FullAccess` permissions.

Setup of credentials must be done twice by now.

```
aws configure
```
(This is for the script)

and, write a `.boto` file under the current folder using `boto_example` as template.
(This is for ansible).

Credential setup process will change in the future.

## TODO

- Integration with MySQL Sandbox
- Full EC container service support for simple deploys.
- Deploy of custom binaries (special for projects that needs an special compilation).


## HOWTO

### Configuration

Please check variables in `.create_ec2_tutorial`.

```
# Default variables
# tag and description of the instances
tagsName="mysql"
tagsValue="breakfixlab"
KEY=breakfixlab
IMAGE=Breakfixlab_PL16
INSTANCE_SIZE="m1.small"

SOURCE_IMAGE_REGION="us-west-1"
INSTANCE_OUT=".db"
```


### SecurityGroups

Run:

```
./create_ec2_tutorial.sh -s
```

### Ansible configuration

Use .boto file.


### Update information

```
./create_ec2_tutorial.sh -U
```


### General Information

It uses the `.db` file. Ensure you have updated the db. Use [Update Information](## Update information)

```
./create_ec2_tutorial.sh -I
```


### Add instances using ansible

Add credentials in .boto


```
./create_ec2_tutorial.sh  -r us-west-1 -s -n1   # This prepares the files to be use in the next step (ec2-vars)
./create_ec2_tutorial.sh  -r us-west-1 -a       # This add the hosts in the ec2-vars/<nameofyourproject>_<region>.yml
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
