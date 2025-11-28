#!/bin/bash
#############################################
# ANSIBLE SLAVE SERVER USER DATA SCRIPT
# Configures: SSH access from Ansible master
#############################################

set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Ansible Slave Server Setup..."
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

echo "=========================================="
echo "Ansible Slave Server Setup Complete!"
echo "=========================================="
echo "This server is ready to receive Ansible commands."
echo "=========================================="
