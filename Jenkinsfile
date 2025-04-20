pipeline {
    agent any

    environment {
        GITHUB_TOKEN = credentials('github-pat')  // GitHub Token for release
        DOCKER_CREDENTIALS = credentials('docker-hub')  // Docker Hub credentials stored in Jenkins
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

        stage('Login to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                    }
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
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

        stage('Upload Docker Image URL to GitHub Release') {
            steps {
                script {
                    def tagName = "v" + new Date().format("yyyy.MM.dd.HHmmss")
                    def dockerImageUrl = "premnikumbh/simple-java-maven-app:${tagName}"
                    
                    echo "📦 Creating release and uploading Docker image reference..."

                    // Create the release
                    def releaseResponse = sh(script: """
                        curl -s -X POST \
                          -H "Authorization: token ${GITHUB_TOKEN}" \
                          -H "Accept: application/vnd.github+json" \
                          https://api.github.com/repos/premnikumbh/simple-java-maven-app/releases \
                          -d '{
                            "tag_name": "${tagName}",
                            "name": "Docker Image Release ${tagName}",
                            "body": "Automated release for Docker image: ${dockerImageUrl}",
                            "draft": false,
                            "prerelease": false
                        }'
                    """, returnStdout: true).trim()

                    // Get the upload URL for the release
                    def uploadUrl = readJSON(text: releaseResponse).upload_url.split("{")[0]

                    // Upload the Docker image reference URL
                    sh """
                        curl -s -X POST \
                          -H "Authorization: token ${GITHUB_TOKEN}" \
                          -H "Content-Type: application/json" \
                          -d '{"name": "${dockerImageUrl}", "url": "https://hub.docker.com/r/premnikumbh/simple-java-maven-app/tags"}' \
                          "${uploadUrl}?name=docker_image_url_${tagName}.json"
                    """
                }
            }
        }

        stage('Upload Artifact to GitHub Release') {
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
