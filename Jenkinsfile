/**
 * DevOps Lab - Complete CI/CD Pipeline
 * 
 * This Jenkinsfile implements a full CI/CD pipeline with:
 * 1. Checkout - Fetch code from Git
 * 2. Build & Test - Maven build with unit tests
 * 3. SonarQube Analysis - Code quality analysis
 * 4. Package & Upload to Nexus - Artifact management
 * 5. Deploy via Ansible - Automated deployment
 * 6. Sanity Check - Health check verification
 * 
 * Prerequisites:
 * - Jenkins credentials configured:
 *   - nexus-credentials: Username/Password for Nexus
 *   - sonarqube-token: Secret text for SonarQube
 *   - ansible-ssh-key: SSH private key for Ansible Master
 * - Jenkins tools configured:
 *   - Maven: maven-3.9
 *   - JDK: jdk-17
 * - SonarQube server configured in Jenkins (name: SonarQube)
 */

pipeline {
    agent any

    // Environment variables
    environment {
        // Application settings
        APP_NAME = 'demo-crud-app'
        APP_VERSION = '1.0.0'
        
        // Paths
        MAVEN_HOME = tool 'maven-3.9'
        JAVA_HOME = tool 'jdk-17'
        PATH = "${MAVEN_HOME}/bin:${JAVA_HOME}/bin:${env.PATH}"
        
        // Nexus settings (update with your Nexus server IP)
        NEXUS_URL = "http://${NEXUS_IP}:8081"
        NEXUS_REPO = 'maven-releases'
        NEXUS_CREDENTIALS = credentials('nexus-credentials')
        
        // SonarQube settings (update with your SonarQube server IP)
        SONARQUBE_URL = "http://${SONARQUBE_IP}:9000"
        
        // Ansible settings (update with your Ansible Master IP)
        ANSIBLE_MASTER_IP = "${ANSIBLE_MASTER_IP}"
        APP_SERVER_IP = "${APP_SERVER_IP}"
    }

    // Pipeline parameters
    parameters {
        string(name: 'APP_VERSION', defaultValue: '1.0.0', description: 'Application version to deploy')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip unit tests')
        booleanParam(name: 'SKIP_SONAR', defaultValue: false, description: 'Skip SonarQube analysis')
    }

    // Build options
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        /**
         * Stage 1: Checkout
         * Fetch the source code from Git
         */
        stage('Checkout') {
            steps {
                echo "=========================================="
                echo "Stage: Checkout"
                echo "=========================================="
                
                // Clean workspace before checkout
                cleanWs()
                
                // Checkout code
                // Option 1: From GitHub (uncomment and update URL)
                // git branch: 'main',
                //     url: 'https://github.com/your-username/your-repo.git'
                
                // Option 2: From local workspace (for learning)
                checkout scm
                
                // Display checkout info
                sh 'echo "Current directory: $(pwd)"'
                sh 'ls -la'
            }
        }

        /**
         * Stage 2: Build & Test
         * Compile code and run unit tests with Maven
         */
        stage('Build & Test') {
            steps {
                echo "=========================================="
                echo "Stage: Build & Test"
                echo "=========================================="
                
                dir('app') {
                    script {
                        if (params.SKIP_TESTS) {
                            echo "Skipping tests as requested..."
                            sh 'mvn clean package -DskipTests'
                        } else {
                            echo "Running Maven build with tests..."
                            sh 'mvn clean package'
                        }
                    }
                }
            }
            post {
                always {
                    // Archive test results
                    dir('app') {
                        junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
                    }
                }
                success {
                    echo "Build successful!"
                    // Archive the JAR file
                    dir('app') {
                        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                    }
                }
            }
        }

        /**
         * Stage 3: SonarQube Analysis
         * Perform code quality analysis
         */
        stage('SonarQube Analysis') {
            when {
                expression { !params.SKIP_SONAR }
            }
            steps {
                echo "=========================================="
                echo "Stage: SonarQube Analysis"
                echo "=========================================="
                
                dir('app') {
                    withSonarQubeEnv('SonarQube') {
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                            sh """
                                mvn sonar:sonar \
                                    -Dsonar.projectKey=${APP_NAME} \
                                    -Dsonar.projectName='${APP_NAME}' \
                                    -Dsonar.projectVersion=${params.APP_VERSION} \
                                    -Dsonar.host.url=${SONARQUBE_URL} \
                                    -Dsonar.login=${SONAR_TOKEN}
                            """
                        }
                    }
                }
            }
        }

        /**
         * Stage 3.5: Quality Gate
         * Wait for SonarQube Quality Gate result
         */
        stage('Quality Gate') {
            when {
                expression { !params.SKIP_SONAR }
            }
            steps {
                echo "=========================================="
                echo "Stage: Quality Gate"
                echo "=========================================="
                
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        /**
         * Stage 4: Upload to Nexus
         * Publish the built artifact to Nexus repository
         */
        stage('Upload to Nexus') {
            steps {
                echo "=========================================="
                echo "Stage: Upload to Nexus"
                echo "=========================================="
                
                dir('app') {
                    script {
                        // Find the JAR file
                        def jarFile = sh(script: "ls target/*.jar | grep -v original | head -1", returnStdout: true).trim()
                        echo "Uploading artifact: ${jarFile}"
                        
                        // Upload using Maven deploy plugin
                        withCredentials([usernamePassword(credentialsId: 'nexus-credentials', 
                                                          usernameVariable: 'NEXUS_USER', 
                                                          passwordVariable: 'NEXUS_PASS')]) {
                            sh """
                                mvn deploy:deploy-file \
                                    -DgroupId=com.example \
                                    -DartifactId=${APP_NAME} \
                                    -Dversion=${params.APP_VERSION} \
                                    -Dpackaging=jar \
                                    -Dfile=${jarFile} \
                                    -DrepositoryId=nexus-releases \
                                    -Durl=${NEXUS_URL}/repository/${NEXUS_REPO}/ \
                                    -DgeneratePom=true \
                                    -s /dev/stdin << EOF
<settings>
  <servers>
    <server>
      <id>nexus-releases</id>
      <username>\${NEXUS_USER}</username>
      <password>\${NEXUS_PASS}</password>
    </server>
  </servers>
</settings>
EOF
                            """
                        }
                    }
                }
            }
        }

        /**
         * Stage 5: Deploy via Ansible
         * Trigger Ansible playbook to deploy the application
         */
        stage('Deploy via Ansible') {
            steps {
                echo "=========================================="
                echo "Stage: Deploy via Ansible"
                echo "=========================================="
                
                script {
                    // SSH into Ansible Master and run playbook
                    sshagent(credentials: ['ansible-ssh-key']) {
                        withCredentials([usernamePassword(credentialsId: 'nexus-credentials', 
                                                          usernameVariable: 'NEXUS_USER', 
                                                          passwordVariable: 'NEXUS_PASS')]) {
                            sh """
                                ssh -o StrictHostKeyChecking=no ubuntu@${ANSIBLE_MASTER_IP} '
                                    cd /home/ubuntu/ansible && \
                                    export APP_VERSION=${params.APP_VERSION} && \
                                    export NEXUS_URL=${NEXUS_URL} && \
                                    export NEXUS_USER=${NEXUS_USER} && \
                                    export NEXUS_PASSWORD=${NEXUS_PASS} && \
                                    ansible-playbook deploy_app.yml -v
                                '
                            """
                        }
                    }
                }
            }
        }

        /**
         * Stage 6: Sanity Check
         * Verify the application is running and healthy
         */
        stage('Sanity Check') {
            steps {
                echo "=========================================="
                echo "Stage: Sanity Check"
                echo "=========================================="
                
                script {
                    // Wait for application to be fully up
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Health check
                    def healthCheckUrl = "http://${APP_SERVER_IP}:8080/actuator/health"
                    echo "Checking health endpoint: ${healthCheckUrl}"
                    
                    def maxRetries = 5
                    def retryCount = 0
                    def healthy = false
                    
                    while (retryCount < maxRetries && !healthy) {
                        try {
                            def response = sh(
                                script: "curl -s -o /dev/null -w '%{http_code}' ${healthCheckUrl}",
                                returnStdout: true
                            ).trim()
                            
                            if (response == '200') {
                                echo "Health check passed! Response code: ${response}"
                                healthy = true
                            } else {
                                echo "Health check returned: ${response}. Retrying..."
                                retryCount++
                                sleep(time: 10, unit: 'SECONDS')
                            }
                        } catch (Exception e) {
                            echo "Health check failed: ${e.message}. Retrying..."
                            retryCount++
                            sleep(time: 10, unit: 'SECONDS')
                        }
                    }
                    
                    if (!healthy) {
                        error("Application health check failed after ${maxRetries} attempts!")
                    }
                    
                    // Test API endpoint
                    echo "Testing API endpoint..."
                    sh "curl -s http://${APP_SERVER_IP}:8080/ | head -20"
                }
            }
        }
    }

    // Post-build actions
    post {
        success {
            echo """
            ============================================
            PIPELINE COMPLETED SUCCESSFULLY!
            ============================================
            Application: ${APP_NAME}
            Version: ${params.APP_VERSION}
            App URL: http://${APP_SERVER_IP}:8080
            Health: http://${APP_SERVER_IP}:8080/actuator/health
            ============================================
            """
        }
        failure {
            echo """
            ============================================
            PIPELINE FAILED!
            ============================================
            Please check the logs above for details.
            ============================================
            """
        }
        always {
            // Clean up workspace
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: true,
                    disableDeferredWipeout: true,
                    notFailBuild: true)
        }
    }
}
