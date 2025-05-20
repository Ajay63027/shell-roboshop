#!/bin/bash
uid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
logfolder="/var/log/shell_scriptlogs"
script_name=$(echo $0 | cut -d "." -f1)
logfile="$logfolder/$script_name.log"

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

dnf module disable nodejs -y
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling nodejs"

dnf install nodejs -y
VALIDATE $? "installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "creating a roboshop user"

mkdir -p /app 
VALIDATE $? "creating app folder"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "downloading catalogue"

cd /app 
VALIDATE $? "moved to app folder"

unzip /tmp/catalogue.zip
VALIDATE $? "unziping catalogue folder"

npm install 
VALIDATE $? "installing packages"

cp catalogue.service.txt /etc/systemd/system/catalogue.service
VALIDATE $? "creating syctlservices"

systemctl daemon-reload
VALIDATE $? "demonreload"

systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "enable and start"

dnf install mongodb-mongosh -y
VALIDATE $? "installing mongoclient"

mongosh --host MONGODB-SERVER-IPADDRESS </app/db/master-data.js

VALIDATE $? "loading data"



