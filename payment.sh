#!/bin/bash
START_TIME=$(date +%s)
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
echo "please enter rabbitmq user password"
read -s rabbitmq_PASSWD

VALIDATE(){
    if [ $1 -eq 0 ];
  then
    echo -e "$2   $G successfully $N"  | tee -a $logfile
  else 
    echo -e "$2  $R failed $N"  | tee -a $logfile
    exit 1
   fi
}

dnf install python3 gcc python3-devel -y &>>$logfile
VALIDATE $? "installing python3"


id roboshop
if [ $? -ne 0 ];
then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logfile
VALIDATE $? "creating a roboshop user"
else 
echo -e "user already exist $Y Skipping this part $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$logfile
VALIDATE $? "downloading payment file"

cd /app 
rm -rf /app/*
unzip /tmp/payment.zip
VALIDATE $? "unzipping payment"


pip3 install -r requirements.txt &>>$logfile
VALIDATE $? "downloading dependies"

cp $script_dir/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload
VALIDATE $? "deamon-reload"

systemctl enable payment 
systemctl start payment

VALIDATE $? "enable and start payment"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "total time taken : $TOTAL_TIME seconds"