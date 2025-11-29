#!/bin/bash
#############################################
# SONARQUBE SERVER USER DATA SCRIPT
# Installs: Java 17, SonarQube Community Edition
#############################################

set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting SonarQube Server Setup..."
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
    lsb-release \
    software-properties-common \
    unzip \
    wget

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
# Configure System for SonarQube
#############################################
echo "Configuring system for SonarQube..."

# Increase virtual memory areas
echo "vm.max_map_count=524288" >> /etc/sysctl.conf
echo "fs.file-max=131072" >> /etc/sysctl.conf
sysctl -p

# Set ulimits
cat >> /etc/security/limits.conf <<EOF
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF

#############################################
# Download and Install SonarQube
#############################################
echo "Downloading SonarQube..."
cd /opt

# Download SonarQube Community Edition (LTS)
SONARQUBE_VERSION="10.3.0.82913"
wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip

# Extract and rename (do this BEFORE creating user to avoid directory conflict)
unzip -q sonarqube-${SONARQUBE_VERSION}.zip
mv sonarqube-${SONARQUBE_VERSION} sonarqube

#############################################
# Create SonarQube User
#############################################
echo "Creating SonarQube user..."
# Create user with /opt/sonarqube as home (directory already exists from extraction)
useradd -r -d /opt/sonarqube -s /bin/bash sonarqube

# Set ownership
chown -R sonarqube:sonarqube /opt/sonarqube

#############################################
# Configure SonarQube
#############################################
echo "Configuring SonarQube..."

# Update sonar.properties for embedded H2 database (lab use only)
cat >> /opt/sonarqube/conf/sonar.properties <<EOF

# Web Server
sonar.web.host=0.0.0.0
sonar.web.port=9000

# Elasticsearch
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError

# Logging
sonar.log.level=INFO
EOF

#############################################
# Create Systemd Service
#############################################
echo "Creating SonarQube systemd service..."

cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF

#############################################
# Start SonarQube
#############################################
echo "Starting SonarQube..."
systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

# Wait for SonarQube to start
echo "Waiting for SonarQube to start..."
sleep 60

# Check if SonarQube is running
while ! curl -s http://localhost:9000/api/system/status | grep -q "UP"; do
    echo "Waiting for SonarQube to be ready..."
    sleep 10
done

echo "=========================================="
echo "SonarQube Server Setup Complete!"
echo "=========================================="
echo "Access SonarQube at: http://<public-ip>:9000"
echo "Default credentials: admin/admin"
echo ""
echo "POST-SETUP STEPS:"
echo "1. Log in and change the admin password"
echo "2. Go to: Administration > Security > Users"
echo "3. Create a token for Jenkins integration"
echo "=========================================="
