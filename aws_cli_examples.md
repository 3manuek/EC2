
# AWS new cli examples

## How to properly `describe-instances`

Describe by columns and filtering:

```
aws ec2 describe-instances --region us-west-1 --filters 'Name=tag:mysql,Values=breakfixlab' --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId,InstanceType,Platform,Tags.Value,State.Code,Tags.Values]'  --output table
```

A smaller output:

```
Macintosh:EC2 emanuel$ aws ec2 describe-instances \
--region us-west-1 --filters 'Name=tag:mysql,Values=breakfixlab' \
--query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId,InstanceType]'  \
--output table
```

```
-----------------------------------------------------
|                 DescribeInstances                 |
+-------------+----------+--------------+-----------+
|  us-west-1a |  running |  i-5f03deea  |  t1.micro |
+-------------+----------+--------------+-----------+
```


# Installing and fixing problems in machines

First try:

```
pip install awscli
```

If fails in mac, you will probably need to go through xcode installation  (Thanks
  to the failing upgrade xcode in El Capitan).

```
xcode-select --install
brew reinstall python
pip install awscli
```
