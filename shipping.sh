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
echo "please enter roboshop user password"
read -s MYSQL_PASSWD

VALIDATE(){
    if [ $1 -eq 0 ];
  then
    echo -e "$2   $G successfully $N"  | tee -a $logfile
  else 
    echo -e "$2  $R failed $N"  | tee -a $logfile
    exit 1
   fi
}

dnf install maven -y &>>$logfile
VALIDATE $? "installing maven and java"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$logfile
VALIDATE $? "downloading shipping content"

cd /app 
VALIDATE $? "moving to app folder"


unzip /tmp/shipping.zip &>>$logfile
VALIDATE $? "unzipping shipping file "

mvn clean package &>>$logfile
VALIDATE $? "packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$logfile
VALIDATE $? "moving and renaming jar file"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service &>>$logfile
sudo systemctl unmask shipping.service

systemctl daemon-reload
VALIDATE $? "deamon-reload "

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "enabling and starting "

dnf install mysql -y  &>>$logfile
VALIDATE $? "installing mysql client"

mysql -h mysql.ajay6.space -uroot -p$MYSQL_PASSWD < /app/db/schema.sql &>>$logfile
mysql -h mysql.ajay6.space -uroot -p$MYSQL_PASSWD < /app/db/app-user.sql  &>>$logfile
mysql -h mysql.ajay6.space -uroot -p$MYSQL_PASSWD < /app/db/master-data.sql &>>$logfile
VALIDATE $? "loading data successfull"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo "total time taken : $TOTAL_TIME seconds"
