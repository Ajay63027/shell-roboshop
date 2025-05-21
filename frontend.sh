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
dnf module list nginx &>>$logfile
VALIDATE $? "module list"

dnf module disable nginx -y &>>$logfile
VALIDATE $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$logfile
VALIDATE $? "eabling nginx:1.24"

dnf install nginx -y &>>$logfile
VALIDATE $? "installing nginx"

systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "enable and start"

rm -rf /usr/share/nginx/html/* &>>$logfile
VALIDATE $? "removing default html"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$logfile
VALIDATE $? "downloading frontend file"

cd /usr/share/nginx/html &>>$logfile
VALIDATE $? "moving to html folder"

unzip /tmp/frontend.zip &>>$logfile
VALIDATE $? "unziping frontend file"  &>>$logfile

rm -rf /etc/nginx/nginx.conf  &>>$logfile
VALIDATE $? "removing default nginx"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf  &>>$logfile
VALIDATE $? "copying nginx file"

systemctl restart nginx  &>>$logfile
VALIDATE $? "nginx restart"







