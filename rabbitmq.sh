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

cp $script_di/rabbit.repo /etc/yum.repos.d/rabbitmq.repo

dnf install rabbitmq-server -y &>>$logfile
VALIDATE $? "installing rabbitmq"

systemctl enable rabbitmq-server &>>$logfile
systemctl start rabbitmq-server &>>$logfile
VALIDATE $? "enabling and start rabbitmq"


rabbitmqctl add_user roboshop $rabbitmq_PASSWD &>>$logfile
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$logfile

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "total time taken : $TOTAL_TIME seconds"