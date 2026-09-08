pipeline {
    agent any

    environment {
        ECR_REPO = '701559402152.dkr.ecr.us-east-1.amazonaws.com/tech2-app'
    }

    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t tech2-app .'
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
                    docker tag tech2-app:latest $ECR_REPO:latest
                    docker push $ECR_REPO:latest
                '''
            }
        }
    }
}