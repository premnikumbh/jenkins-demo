pipeline {
    agent any

    environment {
        GITHUB_TOKEN = credentials('github-pat')            // GitHub PAT for release creation
        DOCKER_CREDENTIALS = credentials('docker-pat')      // Docker PAT credential (replace 'docker-hub' with 'docker-pat')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build with Maven') {
            steps {
                echo "🔧 Building the project..."
                sh 'mvn clean install'
            }
        }

        stage('Build & Tag Docker Image') {
            steps {
                script {
                    env.TAG_NAME = "v" + new Date().format("yyyy.MM.dd.HHmmss")
                    env.IMAGE_NAME = "premnikumbh/jenkins-demo:${TAG_NAME}"
                    echo "🔧 Building Docker image with tag ${IMAGE_NAME}"
                    sh "docker build -t ${IMAGE_NAME} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'docker-pat', variable: 'DOCKER_PAT')]) {
                    // Docker login with PAT (no need for username)
                    sh """
                        echo \$DOCKER_PAT | docker login -u 'premnikumbh' --password-stdin
                        docker push ${IMAGE_NAME}
                    """
                }
            }
        }

        stage('Create GitHub Release & Uploads') {
            steps {
                script {
                    def releaseTag = env.TAG_NAME
                    def releaseName = "Release ${releaseTag}"
                    def body = "Automated release from Jenkins\n\nDocker Image: `${env.IMAGE_NAME}`"

                    echo "🚀 Creating GitHub release: ${releaseTag}"

                    // Create GitHub release
                    def createResponse = sh(script: """
                        curl -s -X POST \
                          -H "Authorization: token ${GITHUB_TOKEN}" \
                          -H "Accept: application/vnd.github+json" \
                          https://api.github.com/repos/premnikumbh/jenkins-demo/releases \
                          -d '{
                            "tag_name": "${releaseTag}",
                            "name": "${releaseName}",
                            "body": "${body}",
                            "draft": false,
                            "prerelease": false
                          }'
                    """, returnStdout: true).trim()

                    def releaseJson = readJSON text: createResponse
                    def releaseId = releaseJson.id

                    // Upload the JAR artifact
                    def jarFile = findFiles(glob: 'target/*.jar')[0].path
                    echo "📦 Uploading artifact: ${jarFile}"

                    // Upload JAR file
                    sh """
                        curl -s -X POST \
                          -H "Authorization: token ${GITHUB_TOKEN}" \
                          -H "Content-Type: application/java-archive" \
                          --data-binary @${jarFile} \
                          "https://uploads.github.com/repos/premnikumbh/jenkins-demo/releases/${releaseId}/assets?name=\$(basename ${jarFile})"
                    """

                    // Upload text file with Docker image info
                    def imageInfoFile = "docker-image-${releaseTag}.txt"
                    writeFile file: imageInfoFile, text: "Docker Image: ${env.IMAGE_NAME}"
                    
                    sh """
                        curl -s -X POST \
                          -H "Authorization: token ${GITHUB_TOKEN}" \
                          -H "Content-Type: text/plain" \
                          --data-binary @${imageInfoFile} \
                          "https://uploads.github.com/repos/premnikumbh/jenkins-demo/releases/${releaseId}/assets?name=${imageInfoFile}"
                    """
                }
            }
        }
    }
}
