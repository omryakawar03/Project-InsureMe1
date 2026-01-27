## installation

### In Jenkins Instance Mandatory Checklist
```
aws-cli --version
docker --version
terraform version
trivy --version
kubectl version --client
```

### Jenkins
```
sudo apt update
sudo apt install fontconfig openjdk-21-jre -y
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y
```
### Docker
```
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
```

### docker permissions for jenkins
```
sudo usermod -aG docker jenkins
```
```
sudo chmod 666 /var/run/docker.sock
```
```
sudo systemctl restart docker
sudo systemctl restart jenkins
```

### SonarQube
````
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
````
## Connect to Jenkins 
## Step6: Install Required Plugins:
   **Install below plugins**

`maven integration`
`SonarQube Scanner`
`stage view`
`terraform`
`AWS Credentials`
`docker`
`Docker Commons`
`Docker Pipeline`
`Docker API`
`docker-build-step`

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
       - aws-cred


## Configure Sonar Server: Manage Jenkins->System
   - name: "sonar-server"
   - url:
   - token:
![image](https://github.com/user-attachments/assets/c5d05628-1502-4a92-b722-7ad3eed5d587)

## Restart Jenkins
`sudo systemctl restart jenkins`

## install trivy to image scan 
`vim trivy.sh`
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
```

## Docker Image Build and Push

- configure docker credentials in credentials session  
  <img width="1467" height="825" alt="Screenshot 2026-01-27 at 1 13 19 AM" src="https://github.com/user-attachments/assets/2f10de10-5cf7-43a6-b837-06fba3142115" />

##  Create Pipeline
```groovy
pipeline {
    agent any

    environment {
        
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_IMAGE = "omryakawar/insure-me"
    }

    stages {

        stage('1. Code Pull') {
            steps {
                git branch: 'main',
                url: 'https://github.com/omryakawar03/Project-InsureMe1.git'
            }
        }

        stage('2. Code Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('3. SonarQube Analysis') {
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

        stage('4. Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: true, credentialsId: 'Sonar-token'
                }
            }
        }

        stage('5. Build & Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker') {
                        sh '''
                        docker build -t insure-me .
                        docker tag insure-me ${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_IMAGE}:latest
                        '''
                    }
                }
            }
        }

        stage('6. Trivy Image Scan') {
            steps {
                sh '''
                trivy image ${DOCKER_IMAGE}:latest > trivy-report.txt
                '''
            }
        }

       stage('7. AWS Configure (eks-profile)') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          sh """
          aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile ${AWS_PROFILE}
          aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile ${AWS_PROFILE}
          aws configure set region ${AWS_REGION} --profile ${AWS_PROFILE}
          aws configure list --profile ${AWS_PROFILE}
          """
        }
      }
    }
     stage('8. Terraform Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir("${TF_DIR}") {
            sh """
            export AWS_PROFILE=${AWS_PROFILE}
            terraform init
            terraform apply -auto-approve
            """
          }
        }
      }
    }
     stage('9. Kubernetes Deploy') {
      steps {
         {
          sh """
          kubectl apply -f k8s/namespace.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
          """
        }
      }
    }


    }
}
```
- check your application on `External-IP:8089`
