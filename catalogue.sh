#!/bin/bash
uid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
logfolder="/var/log/shell_scriptlogs"
script_name=$(echo $0 | cut -d "." -f1)
logfile="$logfolder/$script_name.log"
script_dir=$PWD
packages=("nginx" "python3" "mysql" "httpd")


mkdir -p $logfolder

echo "script starting at $(date)" | tee -a $logfile

if [ $uid -ne 0 ]
then
  echo "ERROR:: user does not have permisions to install" &>>$logfile
  exit 1
else
  echo "user  have permissions to install" &>>$logfile
fi

VALIDATE(){
    if [ $1 -eq 0 ];
  then
    echo -e "$2   $G successfully $N"  | tee -a $logfile
  else 
    echo -e "$2  $R failed $N"  | tee -a $logfile
    exit 1
   fi
}

dnf module disable nodejs -y &>>$logfile
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$logfile
VALIDATE $? "enabling nodejs"

dnf install nodejs -y &>>$logfile
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ];
then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logfile
VALIDATE $? "creating a roboshop user"
else 
echo -e "user already exist $Y Skipping this part $N"
fi

mkdir -p /app 
VALIDATE $? "creating app folder"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$logfile
VALIDATE $? "downloading catalogue"

rm -rf /app/*
cd /app 
VALIDATE $? "moved to app folder"


unzip /tmp/catalogue.zip &>>$logfile
VALIDATE $? "unziping catalogue folder"

npm install &>>$logfile
VALIDATE $? "installing packages"

cp $script_dir/catalogue.service.repo etc/systemd/system/catalogue.service
VALIDATE $? "creating syctlservices"

systemctl daemon-reload
VALIDATE $? "demonreload"

systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "enable and start"

cp $script_dir/mongoclient.rep /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$logfile
VALIDATE $? "installing mongoclient"

mongosh --host mongodb.ajay6.space </app/db/master-data.js

VALIDATE $? "loading data"





