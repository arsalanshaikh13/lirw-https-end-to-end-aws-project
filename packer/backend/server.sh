#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
set -euxo pipefail

# db_host=$1
# db_username=$2
# db_password=$3
# db_name=$4
# bucket_name=$5
# aws_region=$6

# =========================================
# COMMANDS TO RUN IN THE APPLICATION SERVER
# =========================================

# ======================================
# INSTALLING MYSQL IN AMAZON LINUX 2023
# ======================================
# (REF: https://dev.to/aws-builders/installing-mysql-on-amazon-linux-2023-1512)

# sudo su - ec2-user
echo "${bucket_name} name of the bucket"
# COPY APP CODE
sudo -u ec2-user cd /home/ec2-user
aws s3 cp s3://${bucket_name}/lirw-three-tier/backend backend --recursive

# no secret name since we are using ssm parameter store
# sudo sed -i "s/<secret-name>/${db_secret_name}/g" backend/configs/DbConfig.js
sudo sed -i "s/<region>/${aws_region}/g" /home/ec2-user/backend/configs/DbConfig.js
# sudo sed -i "s/<react_node_app>/`${db_name}`/g" /home/ec2-user/backend/db.sql
sudo sed -i "s/<react_node_app>/${db_name}/g" /home/ec2-user/backend/db.sql

sudo cat /home/ec2-user/backend/db.sql

chown -R ec2-user:ec2-user /home/ec2-user/backend
chmod -R 755 /home/ec2-user/backend


echo "========== Preparing SQL schema =========="
cp /home/ec2-user/backend/db.sql /tmp/db.sql


sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
# sudo dnf update –y 
sudo dnf install mysql-community-client -y
mysql --version

mysql -h "${db_host}" \
      -u "${db_username}" \
      -p"${db_password}" < /tmp/db.sql


# Update package list and install required packages 
sudo yum update -y 
# sudo yum install -y git 

# Install Node.js (use NodeSource for the latest version) 
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - 
sudo yum install -y nodejs 

# Install PM2 globally 
sudo npm install -g pm2 

# Define variables 
# REPO_URL="https://github.com/learnItRightWay01/react-node-mysql-app.git" 
# BRANCH_NAME="feature/add-logging" 
REPO_DIR="/home/ec2-user/backend" 
ENV_FILE="$REPO_DIR/.env" 

# Clone the repository 
cd /home/ec2-user/backend
# sudo -u ec2-user git clone $REPO_URL 
# cd react-node-mysql-app  

# Checkout to the specific branch 
# sudo -u ec2-user git checkout $BRANCH_NAME 
# cd backend 

# Define the log directory and ensure it exists 
# LOG_DIR="/home/ec2-user/react-node-mysql-app/backend/logs" 
LOG_DIR="/home/ec2-user/backend/logs" 
mkdir -p $LOG_DIR 
sudo chown -R ec2-user:ec2-user $LOG_DIR


# Append environment variables to the .env file
echo "LOG_DIR=$LOG_DIR" >> "$ENV_FILE"
echo "DB_HOST=${db_host}" >> "$ENV_FILE"
echo "DB_PORT=\"3306\"" >> "$ENV_FILE"
echo "DB_USER=${db_username}" >> "$ENV_FILE"
echo "DB_PASSWORD="${db_password}"" >> "$ENV_FILE"  # Replace with actual password
echo "DB_NAME="${db_name}"" >> "$ENV_FILE"


# Install Node.js dependencies as ec2-user
sudo -u ec2-user npm install

# Start the application using PM2 as ec2-user
sudo -u ec2-user npm run serve

# Ensure PM2 restarts on reboot as ec2-user
sudo -u ec2-user pm2 startup || true
# sudo env PATH=$PATH:/usr/bin \
#  /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user  \
#  --hp /home/ec2-user
echo "Setting up PM2 startup..."

if sudo env PATH=$PATH:/usr/bin \
 /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user \
 --hp /home/ec2-user; then
    echo "PM2 startup configured successfully"
else
    echo "PM2 startup configuration failed, but continuing..."
fi
sudo -u ec2-user pm2 save 

# Install CloudWatch agent
sudo yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOL
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "$LOG_DIR/combined.log",
            "log_group_name": "node-app-logs-lirw-backend",
            "log_stream_name": "{instance_id}-combined-log",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          },
          {
            "file_path": "$LOG_DIR/error.log",
            "log_group_name": "node-app-logs-lirw-backend",
            "log_stream_name": "{instance_id}-error-log",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOL

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
            # "file_path": "/var/log/react-node-mysql-app/backend/combined.log",
            # "file_path": "/var/log/react-node-mysql-app/backend/error.log",




# with ssh it less secure but i will be able to access environment variables in packer, but i will have to edit packer code
# with session manager it will more secure but i have to edit less code