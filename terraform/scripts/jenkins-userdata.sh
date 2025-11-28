#!/bin/bash
#############################################
# JENKINS SERVER USER DATA SCRIPT
# Installs: Java 17, Jenkins, Maven, Git
# Also installs Jenkins plugins
#############################################

set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Jenkins Server Setup..."
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
    jq

#############################################
# Install Java 17
#############################################
echo "Installing Java 17..."
apt-get install -y openjdk-17-jdk

# Set JAVA_HOME
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Verify Java installation
java -version

#############################################
# Install Maven
#############################################
echo "Installing Maven..."
apt-get install -y maven
mvn -version

#############################################
# Install Git
#############################################
echo "Installing Git..."
apt-get install -y git
git --version

#############################################
# Install Jenkins
#############################################
echo "Installing Jenkins..."

# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update and install Jenkins
apt-get update -y
apt-get install -y jenkins

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 60

#############################################
# Install Jenkins Plugins
#############################################
echo "Installing Jenkins plugins..."

# Get initial admin password
JENKINS_URL="http://localhost:8080"
ADMIN_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

# Create CLI jar directory
mkdir -p /var/lib/jenkins/cli

# Wait for Jenkins to be fully ready
while ! curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL/login" | grep -q "200"; do
    echo "Waiting for Jenkins to be ready..."
    sleep 10
done

# Download Jenkins CLI
curl -L "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -o /var/lib/jenkins/cli/jenkins-cli.jar

# Install plugins using CLI
PLUGINS=(
    "workflow-aggregator"         # Pipeline
    "git"                         # Git
    "github"                      # GitHub
    "maven-plugin"                # Maven Integration
    "nexus-artifact-uploader"     # Nexus Artifact Uploader
    "sonar"                       # SonarQube Scanner
    "ssh-agent"                   # SSH Agent
    "ssh-credentials"             # SSH Credentials
    "credentials"                 # Credentials
    "credentials-binding"         # Credentials Binding
    "pipeline-stage-view"         # Pipeline Stage View
    "blueocean"                   # Blue Ocean
    "ws-cleanup"                  # Workspace Cleanup
    "timestamper"                 # Timestamper
    "build-timeout"               # Build Timeout
    "antisamy-markup-formatter"   # OWASP Markup Formatter
    "pipeline-github-lib"         # Pipeline GitHub Library
    "pipeline-utility-steps"      # Pipeline Utility Steps
    "ssh-slaves"                  # SSH Build Agents
    "publish-over-ssh"            # Publish Over SSH
)

for plugin in "${PLUGINS[@]}"; do
    echo "Installing plugin: $plugin"
    java -jar /var/lib/jenkins/cli/jenkins-cli.jar \
        -s "$JENKINS_URL" \
        -auth admin:"$ADMIN_PASSWORD" \
        install-plugin "$plugin" || echo "Failed to install $plugin"
done

# Restart Jenkins to load plugins
echo "Restarting Jenkins to load plugins..."
systemctl restart jenkins

#############################################
# Configure SSH for Ansible access
#############################################
echo "Configuring SSH for Ansible access..."
mkdir -p /home/ubuntu/.ssh
echo "${ansible_public_key}" >> /home/ubuntu/.ssh/authorized_keys
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

#############################################
# Create directory for Jenkins workspace
#############################################
mkdir -p /var/lib/jenkins/workspace
chown -R jenkins:jenkins /var/lib/jenkins/workspace

echo "=========================================="
echo "Jenkins Server Setup Complete!"
echo "=========================================="
echo "Access Jenkins at: http://<public-ip>:8080"
echo "Initial admin password: $ADMIN_PASSWORD"
echo "=========================================="
