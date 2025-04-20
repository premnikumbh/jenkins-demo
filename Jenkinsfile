pipeline {
    agent any

    environment {
        GITHUB_TOKEN = credentials('github-token')  // GitHub Token for release
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    echo "🔧 Compiling the project using Maven..."
                    sh 'mvn clean install'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔧 Building Docker image..."
                    sh 'docker build -t premnikumbh/simple-java-maven-app .'
                }
            }
        }

        stage('Login to Docker') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "🚀 Pushing Docker image to Docker Hub..."
                    sh 'docker push premnikumbh/simple-java-maven-app'
                }
            }
        }

        stage('Create GitHub Release') {
            steps {
                script {
                    echo "🚀 Creating GitHub release with tag..."
                    def tagName = "v" + new Date().format("yyyy.MM.dd.HHmmss")
                    def releaseName = "Jenkins Auto Release ${tagName}"
                    def body = "Automated release from Jenkins on ${new Date()}"

                    sh """
                    curl -s -X POST \
                      -H "Authorization: token ${GITHUB_TOKEN}" \
                      -H "Accept: application/vnd.github+json" \
                      https://api.github.com/repos/premnikumbh/simple-java-maven-app/releases \
                      -d '{
                        "tag_name": "${tagName}",
                        "name": "${releaseName}",
                        "body": "${body}",
                        "draft": false,
                        "prerelease": false
                    }'
                    """
                }
            }
        }

        stage('Upload Artifact to Release') {
            steps {
                script {
                    def tagName = "v" + new Date().format("yyyy.MM.dd.HHmmss")
                    def jarFile = findFiles(glob: 'target/*.jar')[0].path

                    echo "📦 Uploading artifact: ${jarFile}"

                    sh """
                    curl -s -X POST \
                      -H "Authorization: token ${GITHUB_TOKEN}" \
                      -H "Content-Type: application/java-archive" \
                      --data-binary @${jarFile} \
                      "https://uploads.github.com/repos/premnikumbh/simple-java-maven-app/releases/assets?name=${jarFile}&tag=${tagName}"
                    """
                }
            }
        }
    }
}
