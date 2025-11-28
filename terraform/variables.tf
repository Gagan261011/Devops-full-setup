#############################################
# TERRAFORM VARIABLES
# DevOps Lab Environment - Learning Setup
#############################################

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "devops-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type for all servers"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  # You must create this key pair in AWS before running terraform
  # Or change this to an existing key pair name
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into instances (your IP)"
  type        = string
  default     = "0.0.0.0/0"  # For learning; restrict in production
}

# Ubuntu 22.04 LTS AMI IDs by region (x86_64, hvm:ebs-ssd)
# These are official Canonical AMIs - update if needed
variable "ubuntu_ami" {
  description = "Ubuntu 22.04 LTS AMI ID"
  type        = map(string)
  default = {
    "us-east-1"      = "ami-0c7217cdde317cfec"
    "us-east-2"      = "ami-0b8b44ec9a8f90422"
    "us-west-1"      = "ami-0ce2cb35386fc22e9"
    "us-west-2"      = "ami-008fe2fc65df48dac"
    "eu-west-1"      = "ami-0905a3c97561e0b69"
    "eu-central-1"   = "ami-0faab6bdbac9486fb"
    "ap-south-1"     = "ami-03f4878755434977f"
    "ap-southeast-1" = "ami-078c1149d8ad719a7"
  }
}

variable "nexus_admin_password" {
  description = "Nexus admin password (will be set after first login)"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "sonarqube_token" {
  description = "SonarQube token for Jenkins (create after SonarQube is up)"
  type        = string
  default     = "squ_placeholder_token"
  sensitive   = true
}

# Tags for all resources
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "learning"
    Project     = "devops-lab"
    ManagedBy   = "terraform"
  }
}
