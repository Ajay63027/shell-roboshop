#!/bin/bash 

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0a7153f8526f29a8e"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payments" "dispatch" "frontend")
ZONE_ID="Z041894539JBJUU4ES2BO"
DOMAIN_NAME="ajay6.space"

for instance in ${INSTANCES[@]}
 do 
  INSTANCEID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0a7153f8526f29a8e --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)
   if [ $instance != frontend ]
   then
     IP=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
   else
     IP=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
   fi
   echo "$instance ID IP address: $IP"

aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "creating OR updating a record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$instance'.'$DOMAIN_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '
  done