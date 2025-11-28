#!/bin/bash
#############################################
# APPLICATION SERVER USER DATA SCRIPT
# Installs: Java 17, prepares for app deployment
#############################################

set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Application Server Setup..."
echo "=========================================="

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    python3 \
    python3-pip

#############################################
# Install Java 17
#############################################
echo "Installing Java 17..."
apt-get install -y openjdk-17-jdk

# Set JAVA_HOME
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

java -version

#############################################
# Configure SSH for Ansible Master Access
#############################################
echo "Configuring SSH for Ansible Master access..."

mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Add Ansible master's public key to authorized_keys
echo "${ansible_public_key}" >> /home/ubuntu/.ssh/authorized_keys

chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

#############################################
# Configure sudo without password
#############################################
echo "Configuring passwordless sudo for ubuntu user..."
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
chmod 440 /etc/sudoers.d/ubuntu

#############################################
# Create Application User and Directory
#############################################
echo "Creating application user and directory..."

# Create application user
useradd -r -m -d /home/appuser -s /bin/bash appuser

# Create application directory
mkdir -p /opt/app
chown -R appuser:appuser /opt/app
chmod 755 /opt/app

# Create log directory
mkdir -p /var/log/app
chown -R appuser:appuser /var/log/app

echo "=========================================="
echo "Application Server Setup Complete!"
echo "=========================================="
echo "Directory /opt/app is ready for deployment."
echo "Application will run on port 8080."
echo "=========================================="
