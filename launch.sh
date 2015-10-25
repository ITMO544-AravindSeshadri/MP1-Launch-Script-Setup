#!/bin/bash 
declare -a instance_list
mapfile -t instance_list < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $4 --security-group-ids $5 --subnet-id $6 --associate-public-ip-address --iam-instance-profile Name=$7 --user-data file:///home/controller/Documents/MP1/Environment-Setup/webserver.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")
echo "Waiting for instance/instances ${instance_list[@]} to launch...."
aws ec2 wait instance-running --instance-ids ${instance_list[@]} 
echo "Instance/Instances ${instance_list[@]} up and running...."
aws elb create-load-balancer --load-balancer-name MP1LoadBalancer --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups sg-924eccf6 --subnets subnet-71d58014
aws elb register-instances-with-load-balancer --load-balancer-name MP1LoadBalancer --instances ${instance_list[@]}
aws elb configure-health-check --load-balancer-name MP1LoadBalancer --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3
aws autoscaling create-launch-configuration --launch-configuration-name ITMO-544-launch-config --image-id ami-5189a661 --key-name ITMO544_AravindLaptop --security-groups sg-924eccf6 --instance-type t2.micro --user-data /home/controller/Documents/Environment-Setup/install-env.sh --iam-instance-profile phpdeveloperRole
aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name ITMO-544-launch-config --load-balancer-names MP1LoadBalancer --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-71d58014
aws rds create-db-instance --db-name ITMO544AravindDb --db-instance-identifier ITMO544AravindDb --db-instance-class db.t2.micro --engine MySql --allocated-storage 20 --master-username aravind --master-user-password password
aws rds create-db-instance-read-replica --db-instance-identifier ITMO544AravindDbReadOnly --source-db-instance-identifier ITMO544AravindDb --db-instance-class db.t2.micro