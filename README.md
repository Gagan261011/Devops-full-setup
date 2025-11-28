# DevOps Full Setup - Learning Lab Environment

A complete, one-click DevOps lab environment for learning CI/CD pipelines, infrastructure as code, and deployment automation.

## 🎯 Overview

This project creates a complete DevOps environment on AWS including:

| Server | Purpose | Port |
|--------|---------|------|
| Jenkins | CI/CD Orchestration | 8080 |
| SonarQube | Code Quality Analysis | 9000 |
| Nexus | Artifact Repository | 8081 |
| Ansible Master | Configuration Management | SSH (22) |
| Ansible Slave | Additional Automation | SSH (22) |
| Application Server | Java App Deployment | 8080 |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS VPC (10.0.0.0/16)                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Public Subnet (10.0.1.0/24)                │    │
│  │                                                         │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐               │    │
│  │  │ Jenkins │  │SonarQube│  │  Nexus  │               │    │
│  │  │  :8080  │  │  :9000  │  │  :8081  │               │    │
│  │  └────┬────┘  └────┬────┘  └────┬────┘               │    │
│  │       │            │            │                      │    │
│  │       └────────────┼────────────┘                      │    │
│  │                    │                                    │    │
│  │  ┌─────────┐  ┌────┴────┐  ┌─────────┐               │    │
│  │  │ Ansible │──│ Ansible │  │   App   │               │    │
│  │  │  Slave  │  │  Master │──│ Server  │               │    │
│  │  └─────────┘  └─────────┘  │  :8080  │               │    │
│  │                            └─────────┘               │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Terraform** >= 1.0.0 installed
4. **SSH Key Pair** created in AWS (note the name)

### AWS CLI Configuration
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your default output format (json)
```

### Verify Terraform Installation
```bash
terraform --version
```

## 🚀 Quick Start

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/your-repo/devops-full-setup.git
cd devops-full-setup/terraform

# Create terraform.tfvars file
cat > terraform.tfvars << EOF
aws_region     = "us-east-1"
key_name       = "your-ssh-key-name"
allowed_ssh_cidr = "YOUR_IP/32"  # Replace with your IP
EOF
```

### Step 2: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (type 'yes' when prompted)
terraform apply
```

### Step 3: Wait and Verify

Wait 5-10 minutes for user_data scripts to complete, then check:

```bash
# View all outputs
terraform output

# Get specific URLs
terraform output jenkins_url
terraform output sonarqube_url
terraform output nexus_url
```

## 🔧 Post-Deployment Configuration

### 1. Jenkins Setup

1. **Get Initial Password:**
   ```bash
   # SSH to Jenkins server
   ssh -i your-key.pem ubuntu@<jenkins_ip>
   
   # Get password
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

2. **Access Jenkins:** `http://<jenkins_ip>:8080`

3. **Complete Setup Wizard:**
   - Paste the initial password
   - Install suggested plugins
   - Create admin user
   - Configure Jenkins URL

4. **Install Additional Plugins:**
   Go to Manage Jenkins > Plugins > Available and install:
   - Nexus Artifact Uploader
   - SonarQube Scanner
   - Publish Over SSH

5. **Configure Tools:**
   Go to Manage Jenkins > Tools:
   - **JDK:** Name: `jdk-17`, Install automatically (Oracle JDK 17)
   - **Maven:** Name: `maven-3.9`, Install from Apache 3.9.x

6. **Configure Credentials:**
   Go to Manage Jenkins > Credentials > Global:
   - `nexus-credentials` - Username/Password (admin/your-password)
   - `sonarqube-token` - Secret text (from SonarQube)
   - `ansible-ssh-key` - SSH Private Key (from terraform/generated/)

7. **Configure SonarQube Server:**
   Go to Manage Jenkins > System > SonarQube servers:
   - Name: `SonarQube`
   - Server URL: `http://<sonarqube_ip>:9000`
   - Authentication token: (select the sonarqube-token credential)

### 2. SonarQube Setup

1. **Access SonarQube:** `http://<sonarqube_ip>:9000`

2. **Login:** admin / admin

3. **Change Password** (required on first login)

4. **Generate Token for Jenkins:**
   - Go to: Administration > Security > Users
   - Click on admin user
   - Go to Security tab
   - Generate token, name it "jenkins"
   - Copy the token (save it!)

### 3. Nexus Setup

1. **Get Initial Password:**
   ```bash
   ssh -i your-key.pem ubuntu@<nexus_ip>
   sudo cat /opt/nexus/sonatype-work/nexus3/admin.password
   ```

2. **Access Nexus:** `http://<nexus_ip>:8081`

3. **Complete Setup Wizard:**
   - Enter initial password
   - Set new password
   - Configure anonymous access (Enable for lab)

4. **Create Maven Repository:**
   - Go to: Settings (gear icon) > Repositories > Create
   - Select: maven2 (hosted)
   - Name: `maven-releases`
   - Version policy: Release
   - Deployment policy: Allow redeploy
   - Click Create

### 4. Ansible Master Configuration

1. **SSH to Ansible Master:**
   ```bash
   ssh -i your-key.pem ubuntu@<ansible_master_ip>
   ```

2. **Update Inventory:**
   ```bash
   cd /home/ubuntu/ansible
   # Edit inventory file with actual IPs from terraform output
   nano inventory
   ```

3. **Test Connectivity:**
   ```bash
   ansible all -m ping
   ```

## 📁 Project Structure

```
devops-full-setup/
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Variable definitions
│   ├── outputs.tf                 # Output definitions
│   ├── scripts/
│   │   ├── jenkins-userdata.sh    # Jenkins installation script
│   │   ├── sonarqube-userdata.sh  # SonarQube installation script
│   │   ├── nexus-userdata.sh      # Nexus installation script
│   │   ├── ansible-master-userdata.sh
│   │   ├── ansible-slave-userdata.sh
│   │   └── app-server-userdata.sh
│   ├── templates/
│   │   └── inventory.tpl          # Ansible inventory template
│   └── generated/                 # Generated files (after apply)
│       ├── ansible_key            # Ansible SSH private key
│       ├── ansible_key.pub        # Ansible SSH public key
│       └── inventory              # Generated inventory
├── ansible/
│   ├── ansible.cfg                # Ansible configuration
│   ├── inventory                  # Inventory file
│   ├── deploy_app.yml             # Main deployment playbook
│   ├── ping_all.yml               # Connectivity test playbook
│   └── install_java.yml           # Java installation playbook
├── app/
│   ├── pom.xml                    # Maven configuration
│   └── src/
│       ├── main/
│       │   ├── java/
│       │   │   └── com/example/demo/
│       │   │       ├── DemoApplication.java
│       │   │       ├── controller/
│       │   │       │   ├── ItemController.java
│       │   │       │   └── HomeController.java
│       │   │       ├── model/
│       │   │       │   └── Item.java
│       │   │       ├── repository/
│       │   │       │   └── ItemRepository.java
│       │   │       └── service/
│       │   │           └── ItemService.java
│       │   └── resources/
│       │       └── application.properties
│       └── test/                   # Unit tests
├── Jenkinsfile                    # CI/CD pipeline definition
└── README.md                      # This file
```

## 🔄 CI/CD Pipeline

The Jenkins pipeline includes these stages:

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Checkout   │───▶│ Build & Test │───▶│  SonarQube   │
└──────────────┘    └──────────────┘    │   Analysis   │
                                        └──────┬───────┘
                                               │
┌──────────────┐    ┌──────────────┐    ┌──────▼───────┐
│Sanity Check  │◀───│Deploy Ansible│◀───│Upload Nexus  │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Creating the Jenkins Pipeline Job

1. In Jenkins, click "New Item"
2. Enter name: `demo-crud-pipeline`
3. Select "Pipeline"
4. Click OK
5. In Pipeline section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your repo URL
   - Branch: */main
   - Script Path: Jenkinsfile
6. Add environment variables (under Build Environment or pipeline):
   - `NEXUS_IP` - Your Nexus server private IP
   - `SONARQUBE_IP` - Your SonarQube server private IP
   - `ANSIBLE_MASTER_IP` - Your Ansible master public IP
   - `APP_SERVER_IP` - Your app server public IP
7. Click Save

### Running the Pipeline

1. Click "Build with Parameters"
2. Adjust parameters if needed
3. Click "Build"
4. Watch the pipeline progress in Blue Ocean or Stage View

## 📡 API Endpoints

Once deployed, the application provides these endpoints:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | / | Application info |
| GET | /api/items | Get all items |
| GET | /api/items/{id} | Get item by ID |
| POST | /api/items | Create item |
| PUT | /api/items/{id} | Update item |
| DELETE | /api/items/{id} | Delete item |
| GET | /api/items/search?name=xxx | Search items |
| GET | /actuator/health | Health check |

### Testing the API

```bash
# Health check
curl http://<app_server_ip>:8080/actuator/health

# Get all items
curl http://<app_server_ip>:8080/api/items

# Create an item
curl -X POST http://<app_server_ip>:8080/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Test Description"}'

# Get specific item
curl http://<app_server_ip>:8080/api/items/1
```

## 🧹 Cleanup

To destroy all resources and avoid AWS charges:

```bash
cd terraform
terraform destroy
# Type 'yes' when prompted
```

## ❓ Troubleshooting

### Jenkins not accessible
```bash
# Check Jenkins status
ssh -i key.pem ubuntu@<jenkins_ip>
sudo systemctl status jenkins
sudo cat /var/log/user-data.log
```

### SonarQube not starting
```bash
# Check logs
ssh -i key.pem ubuntu@<sonarqube_ip>
sudo tail -f /opt/sonarqube/logs/sonar.log
# Check system resources
free -m
```

### Nexus not accessible
```bash
# Check logs
ssh -i key.pem ubuntu@<nexus_ip>
sudo tail -f /opt/nexus/sonatype-work/nexus3/log/nexus.log
```

### Ansible can't connect to hosts
```bash
# On Ansible master, test SSH
ssh -i ~/.ssh/ansible_key ubuntu@<target_ip>

# Check SSH key permissions
ls -la ~/.ssh/
chmod 600 ~/.ssh/ansible_key
```

### Pipeline fails at SonarQube stage
- Verify SonarQube is running
- Check the token is correct in Jenkins credentials
- Ensure SonarQube server is configured in Jenkins

### Pipeline fails at Nexus upload
- Verify Nexus credentials in Jenkins
- Check the maven-releases repository exists
- Ensure artifact version doesn't already exist (or enable redeploy)

## 📚 Learning Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Spring Boot Reference](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Nexus Repository Manager](https://help.sonatype.com/repomanager3)

## 📄 License

This project is for learning purposes. Feel free to use and modify.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

---

**Happy Learning! 🚀**
