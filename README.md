## installation

**Jenkins**
````
sudo apt update
sudo apt install fontconfig openjdk-21-jre  -y
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
````
**Docker**
````

sudo apt-get update
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo usermod -aG docker ubuntu
newgrp docker
sudo chmod 777 /var/run/docker.sock
````
**SonarQube**
````
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
````
## Connect to Jenkins 
## Step6: Install Required Plugins:
   **Install below plugins**

````
maven integration
````
````
SonarQube Scanner
````
````
docker
````
````
stage view
````
## Install  Tools: Manage Jenkins->Tools
   - add SonarQube Scanner: "sonar-scanner"
   - docker: "docker"

### **Configure SonarQube-Scanner and Docker in Global Tool Configuration**

#### SonarQube-Scanner
![image](https://github.com/user-attachments/assets/24589963-9a7e-4d6a-9598-66580c195e30)


#### Docker
![image](https://github.com/user-attachments/assets/289c2e2a-df33-476b-a195-d584db3ef03e)


## Connect to SonarQube
## Log in to Sonarqube and generate token
 - username: admin
 - password: admin
<img width="1902" height="957" alt="image" src="https://github.com/user-attachments/assets/36620768-5f81-440c-b31b-ecf29c609f64" />   


     **SonarQube**
  - Go to  "Manage Jenkins" → Credentials."
  - Click on "Global."
  - Click on "Add Credentials" 
  - Choose "secret text" as the kind of credentials.
  - Enter your sonarqube token and give the credentials an ID (e.g., "sonar-token").
  - Click "create" to save yourcredentials
    
<img width="1470" height="547" alt="Screenshot 2025-12-06 at 3 00 58 PM" src="https://github.com/user-attachments/assets/fd7087d5-acf5-48f6-9e07-4b951f55b88f" />


  - Admin->my account->security->generate token
![image](https://github.com/user-attachments/assets/26cb309d-aa3c-4a74-873f-9e87b2fcce00)

Step5: In Jenkins
     - Manage Jenkins: Credentials
       - Sonar-Token
       - Git-Cred
       - Docker-Cred


## Configure Sonar Server: Manage Jenkins->System
   - name: "sonar-server"
   - url:
   - token:
![image](https://github.com/user-attachments/assets/c5d05628-1502-4a92-b722-7ad3eed5d587)

## Restart Jenkins

##  Create Pipeline
```groovy
pipeline {
    agent any 

    tools {
        maven 'maven'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('code-pull') {
            steps {
                git branch: 'main', url: 'https://github.com/mukundDeo9325/Project-InsureMe1.git'
            }
        }

        stage('code-build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage("code-test-analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=InsureMe \
                        -Dsonar.projectName=InsureMe \
                        -Dsonar.sources=src \
                        -Dsonar.java.binaries=target/classes
                    '''
                }
            }
        }

        stage("code-test-quality gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }


        stage('code-deploy') {
            steps {
                sh 'docker build -t insure-me .'
                sh 'docker run -itd --name insure-me -p 8089:8081 insure-me'
            }
        }
    }
}

```
