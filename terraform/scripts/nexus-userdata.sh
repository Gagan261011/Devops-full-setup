#!/bin/bash
#############################################
# NEXUS REPOSITORY SERVER USER DATA SCRIPT
# Installs: Java 8, Nexus Repository Manager 3
#############################################

set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Nexus Repository Server Setup..."
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
# Install Java 8 (Required for Nexus 3)
#############################################
echo "Installing Java 8..."
apt-get install -y openjdk-8-jdk

# Set JAVA_HOME
echo "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

java -version

#############################################
# Create Nexus User
#############################################
echo "Creating Nexus user..."
useradd -r -m -d /opt/nexus -s /bin/bash nexus

#############################################
# Download and Install Nexus
#############################################
echo "Downloading Nexus..."
cd /opt

# Download latest Nexus 3
NEXUS_VERSION="3.64.0-04"
wget -q https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz

# Extract
tar -xzf nexus-${NEXUS_VERSION}-unix.tar.gz
mv nexus-${NEXUS_VERSION} nexus
mv sonatype-work /opt/nexus/

# Set ownership
chown -R nexus:nexus /opt/nexus

#############################################
# Configure Nexus
#############################################
echo "Configuring Nexus..."

# Set Nexus to run as nexus user
echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc

# Configure JVM options
cat > /opt/nexus/bin/nexus.vmoptions <<EOF
-Xms1024m
-Xmx1024m
-XX:MaxDirectMemorySize=1024m
-XX:+UnlockDiagnosticVMOptions
-XX:+LogVMOutput
-XX:LogFile=../sonatype-work/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=../sonatype-work/nexus3
-Dkaraf.log=../sonatype-work/nexus3/log
-Djava.io.tmpdir=../sonatype-work/nexus3/tmp
EOF

# Set default HTTP port (8081)
cat >> /opt/nexus/etc/nexus-default.properties <<EOF
# Application port
application-port=8081
application-host=0.0.0.0
EOF

#############################################
# Create Systemd Service
#############################################
echo "Creating Nexus systemd service..."

cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOF

#############################################
# Start Nexus
#############################################
echo "Starting Nexus..."
systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

# Wait for Nexus to start
echo "Waiting for Nexus to start (this may take 2-3 minutes)..."
sleep 120

# Check if Nexus is running
while ! curl -s http://localhost:8081/service/rest/v1/status | grep -q "STARTED"; do
    echo "Waiting for Nexus to be ready..."
    sleep 15
done

# Get initial admin password
if [ -f /opt/nexus/sonatype-work/nexus3/admin.password ]; then
    ADMIN_PASSWORD=$(cat /opt/nexus/sonatype-work/nexus3/admin.password)
    echo "Initial admin password: $ADMIN_PASSWORD"
fi

echo "=========================================="
echo "Nexus Repository Server Setup Complete!"
echo "=========================================="
echo "Access Nexus at: http://<public-ip>:8081"
echo "Initial admin password stored in:"
echo "/opt/nexus/sonatype-work/nexus3/admin.password"
echo ""
echo "POST-SETUP STEPS:"
echo "1. Log in with admin and the initial password"
echo "2. Complete the setup wizard"
echo "3. Create a hosted Maven repository:"
echo "   - Name: maven-releases"
echo "   - Version policy: Release"
echo "   - Layout policy: Strict"
echo "4. (Optional) Create maven-snapshots repository"
echo "=========================================="
