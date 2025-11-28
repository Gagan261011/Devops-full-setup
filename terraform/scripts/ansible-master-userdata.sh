#!/bin/bash
#############################################
# ANSIBLE MASTER SERVER USER DATA SCRIPT
# Installs: Ansible, SSH keys, basic playbooks
#############################################

set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Ansible Master Server Setup..."
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
    python3 \
    python3-pip \
    sshpass

#############################################
# Install Ansible
#############################################
echo "Installing Ansible..."
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# Verify installation
ansible --version

#############################################
# Configure SSH Keys
#############################################
echo "Configuring SSH keys..."

# Create .ssh directory
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Write private key for Ansible to use
cat > /home/ubuntu/.ssh/ansible_key <<'PRIVATEKEY'
${ansible_private_key}
PRIVATEKEY

# Write public key
cat > /home/ubuntu/.ssh/ansible_key.pub <<'PUBLICKEY'
${ansible_public_key}
PUBLICKEY

# Add public key to authorized_keys (so Jenkins can SSH here)
echo "${ansible_public_key}" >> /home/ubuntu/.ssh/authorized_keys

# Set proper permissions
chmod 600 /home/ubuntu/.ssh/ansible_key
chmod 644 /home/ubuntu/.ssh/ansible_key.pub
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

#############################################
# Create Ansible Directory Structure
#############################################
echo "Creating Ansible directory structure..."

mkdir -p /home/ubuntu/ansible
mkdir -p /home/ubuntu/ansible/roles
mkdir -p /home/ubuntu/ansible/group_vars
mkdir -p /home/ubuntu/ansible/host_vars

#############################################
# Create Ansible Configuration
#############################################
echo "Creating Ansible configuration..."

cat > /home/ubuntu/ansible/ansible.cfg <<'EOF'
[defaults]
inventory = /home/ubuntu/ansible/inventory
remote_user = ubuntu
private_key_file = /home/ubuntu/.ssh/ansible_key
host_key_checking = False
retry_files_enabled = False
timeout = 30

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF

#############################################
# Create Inventory Template
#############################################
echo "Creating inventory file..."

cat > /home/ubuntu/ansible/inventory <<'EOF'
# Ansible Inventory File
# Update the IP addresses after terraform apply

[app_servers]
app_server ansible_host=REPLACE_APP_SERVER_IP

[ansible_slaves]
ansible_slave ansible_host=REPLACE_ANSIBLE_SLAVE_IP

[all:vars]
ansible_python_interpreter=/usr/bin/python3
nexus_url=http://REPLACE_NEXUS_IP:8081
EOF

#############################################
# Create Deploy Playbook
#############################################
echo "Creating deploy_app.yml playbook..."

cat > /home/ubuntu/ansible/deploy_app.yml <<'EOF'
---
# Deploy Application Playbook
# This playbook downloads the JAR from Nexus and deploys it to the app server

- name: Deploy Spring Boot Application
  hosts: app_servers
  become: yes
  vars:
    app_name: demo-crud-app
    app_version: "{{ lookup('env', 'APP_VERSION') | default('1.0.0', true) }}"
    nexus_url: "{{ lookup('env', 'NEXUS_URL') | default('http://localhost:8081', true) }}"
    nexus_repo: maven-releases
    nexus_user: "{{ lookup('env', 'NEXUS_USER') | default('admin', true) }}"
    nexus_password: "{{ lookup('env', 'NEXUS_PASSWORD') | default('admin123', true) }}"
    app_dir: /opt/app
    app_user: appuser
    app_port: 8080

  tasks:
    - name: Ensure app user exists
      user:
        name: "{{ app_user }}"
        state: present
        system: yes
        shell: /bin/bash

    - name: Create application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'

    - name: Stop existing application (if running)
      systemd:
        name: "{{ app_name }}"
        state: stopped
      ignore_errors: yes

    - name: Download artifact from Nexus
      get_url:
        url: "{{ nexus_url }}/repository/{{ nexus_repo }}/com/example/{{ app_name }}/{{ app_version }}/{{ app_name }}-{{ app_version }}.jar"
        dest: "{{ app_dir }}/{{ app_name }}.jar"
        url_username: "{{ nexus_user }}"
        url_password: "{{ nexus_password }}"
        force: yes
        mode: '0644'
        owner: "{{ app_user }}"
        group: "{{ app_user }}"

    - name: Create systemd service file
      template:
        src: templates/app-service.j2
        dest: /etc/systemd/system/{{ app_name }}.service
        mode: '0644'
      notify: Reload systemd

    - name: Create application service file (inline)
      copy:
        content: |
          [Unit]
          Description={{ app_name }} Spring Boot Application
          After=network.target

          [Service]
          Type=simple
          User={{ app_user }}
          WorkingDirectory={{ app_dir }}
          ExecStart=/usr/bin/java -jar {{ app_dir }}/{{ app_name }}.jar --server.port={{ app_port }}
          Restart=always
          RestartSec=10

          [Install]
          WantedBy=multi-user.target
        dest: /etc/systemd/system/{{ app_name }}.service
        mode: '0644'
      notify: Reload systemd

    - name: Reload systemd daemon
      systemd:
        daemon_reload: yes

    - name: Start and enable application service
      systemd:
        name: "{{ app_name }}"
        state: started
        enabled: yes

    - name: Wait for application to start
      wait_for:
        port: "{{ app_port }}"
        delay: 10
        timeout: 60

    - name: Verify application is running
      uri:
        url: "http://localhost:{{ app_port }}/actuator/health"
        method: GET
        status_code: 200
      register: health_check
      retries: 5
      delay: 5
      until: health_check.status == 200

  handlers:
    - name: Reload systemd
      systemd:
        daemon_reload: yes
EOF

#############################################
# Create a simple test playbook
#############################################
cat > /home/ubuntu/ansible/ping_all.yml <<'EOF'
---
# Simple ping playbook to test connectivity
- name: Test connectivity to all hosts
  hosts: all
  gather_facts: no
  tasks:
    - name: Ping all hosts
      ping:
      register: ping_result

    - name: Show ping result
      debug:
        var: ping_result
EOF

#############################################
# Set ownership
#############################################
chown -R ubuntu:ubuntu /home/ubuntu/ansible

echo "=========================================="
echo "Ansible Master Server Setup Complete!"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "1. Update /home/ubuntu/ansible/inventory with actual IPs"
echo "2. Test connectivity: ansible all -m ping"
echo "3. Run deployment: ansible-playbook deploy_app.yml"
echo "=========================================="
