pipeline {
    agent any
    environment {
        registryName = "myacrrepo5312"
        registryCredential = 'ACR'
        registryUrl = 'myacrrepo5312.azurecr.io'
        dockerImage = ''
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/SasithWickrama/azure-aks-spring-boot']])
            }
        }
        stage ("Build JAR"){
            steps {
                sh "mvn clean install"
            }
        }
        stage ('Build Docker image') {
            steps {
                script {
                    dockerImage = docker.build registryName
                }
            }
        }
        // Uploading Docker images into ACR
        stage('Upload Image to ACR') {
             steps{   
                 script {
                    docker.withRegistry( "http://${registryUrl}", registryCredential ) {
                    dockerImage.push("$BUILD_NUMBER")
                    }
                }
             }
        }
        stage ('Helm Deploy') {
            steps {
                script {
                        sh "helm upgrade first --install mychart --namespace helm-deployment --set image.tag=$BUILD_NUMBER"
                        }
                    }
                }
            }
        }
    
