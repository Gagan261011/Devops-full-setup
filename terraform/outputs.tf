#############################################
# TERRAFORM OUTPUTS
# DevOps Lab Environment - Learning Setup
#############################################

#############################################
# SERVER URLs AND IPs
#############################################

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_private_ip" {
  description = "Jenkins server private IP"
  value       = aws_instance.jenkins.private_ip
}

output "sonarqube_url" {
  description = "SonarQube web UI URL"
  value       = "http://${aws_instance.sonarqube.public_ip}:9000"
}

output "sonarqube_public_ip" {
  description = "SonarQube server public IP"
  value       = aws_instance.sonarqube.public_ip
}

output "sonarqube_private_ip" {
  description = "SonarQube server private IP"
  value       = aws_instance.sonarqube.private_ip
}

output "nexus_url" {
  description = "Nexus web UI URL"
  value       = "http://${aws_instance.nexus.public_ip}:8081"
}

output "nexus_public_ip" {
  description = "Nexus server public IP"
  value       = aws_instance.nexus.public_ip
}

output "nexus_private_ip" {
  description = "Nexus server private IP"
  value       = aws_instance.nexus.private_ip
}

output "ansible_master_public_ip" {
  description = "Ansible Master server public IP"
  value       = aws_instance.ansible_master.public_ip
}

output "ansible_master_private_ip" {
  description = "Ansible Master server private IP"
  value       = aws_instance.ansible_master.private_ip
}

output "ansible_slave_public_ip" {
  description = "Ansible Slave server public IP"
  value       = aws_instance.ansible_slave.public_ip
}

output "ansible_slave_private_ip" {
  description = "Ansible Slave server private IP"
  value       = aws_instance.ansible_slave.private_ip
}

output "app_server_url" {
  description = "Application server URL"
  value       = "http://${aws_instance.app.public_ip}:8080"
}

output "app_server_public_ip" {
  description = "Application server public IP"
  value       = aws_instance.app.public_ip
}

output "app_server_private_ip" {
  description = "Application server private IP"
  value       = aws_instance.app.private_ip
}

#############################################
# VPC AND NETWORKING
#############################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

#############################################
# SSH CONNECTION COMMANDS
#############################################

output "ssh_commands" {
  description = "SSH commands to connect to each server"
  value = <<-EOT

  ============================================
  SSH CONNECTION COMMANDS
  ============================================
  
  Jenkins:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.jenkins.public_ip}
  
  SonarQube:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.sonarqube.public_ip}
  
  Nexus:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.nexus.public_ip}
  
  Ansible Master:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.ansible_master.public_ip}
  
  Ansible Slave:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.ansible_slave.public_ip}
  
  App Server:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip}

  EOT
}

#############################################
# POST-DEPLOYMENT INSTRUCTIONS
#############################################

output "post_deployment_instructions" {
  description = "Steps to complete after terraform apply"
  value = <<-EOT

  ============================================
  POST-DEPLOYMENT INSTRUCTIONS
  ============================================

  1. WAIT FOR SERVERS TO INITIALIZE (5-10 minutes)
     The user_data scripts need time to complete.

  2. GET JENKINS INITIAL PASSWORD:
     ssh -i ${var.key_name}.pem ubuntu@${aws_instance.jenkins.public_ip}
     sudo cat /var/lib/jenkins/secrets/initialAdminPassword

  3. ACCESS JENKINS:
     URL: http://${aws_instance.jenkins.public_ip}:8080
     - Complete initial setup wizard
     - Install suggested plugins + additional plugins (see README)

  4. ACCESS SONARQUBE:
     URL: http://${aws_instance.sonarqube.public_ip}:9000
     Default credentials: admin/admin
     - Change password on first login
     - Generate token for Jenkins: Administration > Security > Users > Tokens

  5. ACCESS NEXUS:
     URL: http://${aws_instance.nexus.public_ip}:8081
     - Get initial admin password:
       ssh -i ${var.key_name}.pem ubuntu@${aws_instance.nexus.public_ip}
       sudo cat /opt/nexus/sonatype-work/nexus3/admin.password
     - Complete setup wizard
     - Create maven-releases repository

  6. CONFIGURE ANSIBLE INVENTORY:
     SSH to Ansible Master and update inventory:
     ssh -i ${var.key_name}.pem ubuntu@${aws_instance.ansible_master.public_ip}
     
     Update /home/ubuntu/ansible/inventory with:
     - app_server ansible_host=${aws_instance.app.private_ip}
     - ansible_slave ansible_host=${aws_instance.ansible_slave.private_ip}

  7. CREATE JENKINS PIPELINE:
     - Create new Pipeline job
     - Use the provided Jenkinsfile
     - Configure credentials (Nexus, SonarQube, Ansible SSH)

  8. TEST THE PIPELINE:
     - Run the pipeline
     - Check application: http://${aws_instance.app.public_ip}:8080

  ============================================
  EOT
}
