pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub') // Jenkins credentials ID
        GIT_CREDENTIALS = credentials('github-pat') // Jenkins credentials ID
        IMAGE_NAME = 'premnikumbh/simple-java-maven-app'
    }

    stages {
        stage('Clone Code') {
            steps {
                git url: 'https://github.com/premnikumbh/simple-java-maven-app.git', branch: 'main'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def version = sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim()
                    env.IMAGE_TAG = "${version}"
                }
                sh """
                docker build -t $IMAGE_NAME:$IMAGE_TAG .
                docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest
                """
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withDockerRegistry([credentialsId: 'docker-hub', url: '']) {
                    sh """
                    docker push $IMAGE_NAME:$IMAGE_TAG
                    docker push $IMAGE_NAME:latest
                    """
                }
            }
        }

        stage('Deploy using Docker Compose') {
            steps {
                sh """
                docker-compose down || true
                docker-compose up -d
                """
            }
        }
    }

    post {
        failure {
            echo 'Build failed!'
        }
        success {
            echo "Build succeeded! Deployed version: $IMAGE_TAG"
        }
    }
}
