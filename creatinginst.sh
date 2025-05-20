#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0a7153f8526f29a8e"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payments" "dispatch" "frontend")
ZONE_ID="Z041894539JBJUU4ES2BO"
DOMAIN_NAME="ajay6.space"

for instance in "${INSTANCES[@]}"
do 
  echo "Launching instance: $instance"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t2.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "Instance $instance launched with ID: $INSTANCE_ID"

  # Wait for instance to be in 'running' state before querying IP
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  if [ "$instance" != "frontend" ]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)
  fi

  echo "$instance IP address: $IP"

  # Optional: You can use the IP to create Route53 records or log somewhere
done
