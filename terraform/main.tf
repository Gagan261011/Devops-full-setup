#############################################
# MAIN TERRAFORM CONFIGURATION
# DevOps Lab Environment - Learning Setup
#############################################
# This creates a complete DevOps lab with:
# - Jenkins, SonarQube, Nexus servers
# - Ansible master/slave
# - Application server
#############################################

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.common_tags
  }
}

#############################################
# VPC AND NETWORKING
#############################################

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#############################################
# SSH KEY FOR ANSIBLE
#############################################

# Generate SSH key pair for Ansible master to connect to slaves
resource "tls_private_key" "ansible" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally (for reference)
resource "local_file" "ansible_private_key" {
  content         = tls_private_key.ansible.private_key_pem
  filename        = "${path.module}/generated/ansible_key"
  file_permission = "0600"
}

# Save public key locally (for reference)
resource "local_file" "ansible_public_key" {
  content  = tls_private_key.ansible.public_key_openssh
  filename = "${path.module}/generated/ansible_key.pub"
}

#############################################
# SECURITY GROUPS
#############################################

# Jenkins Security Group
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Jenkins web UI
  ingress {
    description = "Jenkins HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

# SonarQube Security Group
resource "aws_security_group" "sonarqube" {
  name        = "${var.project_name}-sonarqube-sg"
  description = "Security group for SonarQube server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "SonarQube HTTP"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sonarqube-sg"
  }
}

# Nexus Security Group
resource "aws_security_group" "nexus" {
  name        = "${var.project_name}-nexus-sg"
  description = "Security group for Nexus server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Nexus HTTP"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-nexus-sg"
  }
}

# Ansible Security Group (Master and Slave)
resource "aws_security_group" "ansible" {
  name        = "${var.project_name}-ansible-sg"
  description = "Security group for Ansible servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Allow SSH from within VPC (for Ansible master to connect to slave)
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ansible-sg"
  }
}

# Application Server Security Group
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for Application server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # SSH from VPC (for Ansible deployment)
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Application port
  ingress {
    description = "Application HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

#############################################
# EC2 INSTANCES
#############################################

# Jenkins Server
resource "aws_instance" "jenkins" {
  ami                    = var.ubuntu_ami[var.aws_region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  
  user_data = templatefile("${path.module}/scripts/jenkins-userdata.sh", {
    ansible_public_key = tls_private_key.ansible.public_key_openssh
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-jenkins"
    Role = "jenkins"
  }
}

# SonarQube Server
resource "aws_instance" "sonarqube" {
  ami                    = var.ubuntu_ami[var.aws_region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sonarqube.id]
  
  user_data = file("${path.module}/scripts/sonarqube-userdata.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-sonarqube"
    Role = "sonarqube"
  }
}

# Nexus Server
resource "aws_instance" "nexus" {
  ami                    = var.ubuntu_ami[var.aws_region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nexus.id]
  
  user_data = file("${path.module}/scripts/nexus-userdata.sh")

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-nexus"
    Role = "nexus"
  }
}

# Ansible Master Server
resource "aws_instance" "ansible_master" {
  ami                    = var.ubuntu_ami[var.aws_region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ansible.id]
  
  user_data = templatefile("${path.module}/scripts/ansible-master-userdata.sh", {
    ansible_private_key = tls_private_key.ansible.private_key_pem
    ansible_public_key  = tls_private_key.ansible.public_key_openssh
    ansible_slave_ip    = ""  # Will be updated after apply
    app_server_ip       = ""  # Will be updated after apply
    nexus_ip            = ""  # Will be updated after apply
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-ansible-master"
    Role = "ansible-master"
  }
}

# Ansible Slave Server
resource "aws_instance" "ansible_slave" {
  ami                    = var.ubuntu_ami[var.aws_region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ansible.id]
  
  user_data = templatefile("${path.module}/scripts/ansible-slave-userdata.sh", {
    ansible_public_key = tls_private_key.ansible.public_key_openssh
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-ansible-slave"
    Role = "ansible-slave"
  }
}

# Application Server
resource "aws_instance" "app" {
  ami                    = var.ubuntu_ami[var.aws_region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  
  user_data = templatefile("${path.module}/scripts/app-server-userdata.sh", {
    ansible_public_key = tls_private_key.ansible.public_key_openssh
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-app-server"
    Role = "app-server"
  }
}

#############################################
# NULL RESOURCE TO UPDATE ANSIBLE INVENTORY
#############################################

# Create inventory file after all instances are created
resource "local_file" "ansible_inventory" {
  depends_on = [
    aws_instance.ansible_slave,
    aws_instance.app
  ]

  content = templatefile("${path.module}/templates/inventory.tpl", {
    ansible_slave_ip    = aws_instance.ansible_slave.private_ip
    ansible_slave_public_ip = aws_instance.ansible_slave.public_ip
    app_server_ip       = aws_instance.app.private_ip
    app_server_public_ip = aws_instance.app.public_ip
    nexus_ip            = aws_instance.nexus.private_ip
    nexus_public_ip     = aws_instance.nexus.public_ip
    jenkins_ip          = aws_instance.jenkins.private_ip
    sonarqube_ip        = aws_instance.sonarqube.private_ip
  })
  filename = "${path.module}/generated/inventory"
}

# Create a script to copy inventory to Ansible master
resource "local_file" "copy_inventory_script" {
  depends_on = [local_file.ansible_inventory]

  content = <<-EOT
#!/bin/bash
# Run this script after terraform apply to copy inventory to Ansible master
# Usage: ./copy_inventory.sh

ANSIBLE_MASTER_IP="${aws_instance.ansible_master.public_ip}"
KEY_PATH="${var.key_name}.pem"

echo "Copying inventory to Ansible master..."
scp -i $KEY_PATH -o StrictHostKeyChecking=no generated/inventory ubuntu@$ANSIBLE_MASTER_IP:/home/ubuntu/ansible/inventory

echo "Copying Ansible playbook..."
scp -i $KEY_PATH -o StrictHostKeyChecking=no ../ansible/deploy_app.yml ubuntu@$ANSIBLE_MASTER_IP:/home/ubuntu/ansible/

echo "Done! Ansible master is configured."
EOT
  filename = "${path.module}/generated/copy_inventory.sh"
}
