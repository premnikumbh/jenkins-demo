pipeline {
    agent any

    environment {
        GITHUB_TOKEN = credentials('github-pat')            // GitHub PAT with correct scopes
        DOCKER_CREDENTIALS = credentials('docker-pat')      // Docker PAT credential
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
                    echo "🐳 Building Docker image with tag ${IMAGE_NAME}"
                    sh "docker build -t ${IMAGE_NAME} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'docker-pat', variable: 'DOCKER_PAT')]) {
                    sh """
                        echo \$DOCKER_PAT | docker login -u 'premnikumbh' --password-stdin
                        docker push ${IMAGE_NAME}
                    """
                }
            }
        }

        stage('Tag Git Commit') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                        sh """
                            git config user.name "Jenkins CI"
                            git config user.email "ci@jenkins.local"
                            git tag ${TAG_NAME}
                            git remote set-url origin https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/premnikumbh/jenkins-demo.git
                            git push origin ${TAG_NAME}
                        """
                    }
                    echo "🏷️ Git tag ${TAG_NAME} created and pushed."
                }
            }
        }

        stage('Create GitHub Release & Uploads') {
            steps {
                script {
                    def releaseTag = env.TAG_NAME
                    def releaseName = "Release ${releaseTag}"
                    def body = "🤖 Automated release from Jenkins\n\n🐳 Docker Image: ${env.IMAGE_NAME}"

                    echo "🚀 Creating GitHub release for tag: ${releaseTag}"

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

                    echo "📨 GitHub API raw response:\n${createResponse}"

                    // Try parsing with readJSON first, fallback to jq if it fails
                    def releaseId = ''
                    try {
                        def releaseJson = readJSON text: createResponse
                        releaseId = releaseJson.id
                    } catch (Exception e) {
                        echo "⚠️ readJSON failed: ${e.getMessage()}"
                        echo "⛑️ Falling back to jq"
                        releaseId = sh(script: """echo '${createResponse}' | jq '.id'""", returnStdout: true).trim()
                    }

                    if (!releaseId) {
                        error("❌ Failed to parse release ID. Exiting.")
                    }

                    echo "✅ GitHub Release ID: ${releaseId}"

                    // Upload JAR file
                    def jarFile = findFiles(glob: 'target/*.jar')[0].path
                    echo "📦 Uploading artifact: ${jarFile}"

                    sh """
                        curl -s -X POST \
                          -H "Authorization: token ${GITHUB_TOKEN}" \
                          -H "Content-Type: application/java-archive" \
                          --data-binary @${jarFile} \
                          "https://uploads.github.com/repos/premnikumbh/jenkins-demo/releases/${releaseId}/assets?name=\$(basename ${jarFile})"
                    """

                    // Upload Docker image info file
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
