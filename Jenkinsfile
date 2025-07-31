pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_VERSION', defaultValue: 'v1.0.0', description: 'Version for this deployment')
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to deploy')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    }

    environment {
        SSH_KEY_ID = 'ec2-ssh-key' // Jenkins SSH credential ID
        REMOTE_USER = 'ubuntu'
        REMOTE_HOST = '51.20.181.213'
        REMOTE_DIR = '/home/ubuntu/my_app'
        PORT = '3000'
    }

    tools {
    nodejs 'node-version' // Match the name you configured
}

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${params.BRANCH_NAME}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Mayuri121999/my-app.git'
                    ]]
                ])
            }
        }

        stage('Build') {
            steps {
                sh '''
                    npm install
                    npm run build
                '''
            }
        }

        stage('Deploy') {
            steps {
                sshagent (credentials: ["${env.SSH_KEY_ID}"]) {
                    sh """
                        scp -o StrictHostKeyChecking=no -r ./ ${env.REMOTE_USER}@${env.REMOTE_HOST}:${env.REMOTE_DIR}/releases/${params.DEPLOY_VERSION}
                        ssh ${env.REMOTE_USER}@${env.REMOTE_HOST} 'bash -s' < ./deploy/deploy.sh ${params.ENV} ${params.DEPLOY_VERSION}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    def status = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://${env.REMOTE_HOST}:${env.PORT}", returnStdout: true).trim()
                    if (status != '200') {
                        error("Health check failed, rolling back...")
                    } else {
                        echo "Health check passed: ${status}"
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "Deployment failed. Rolling back..."
            sshagent (credentials: ["${env.SSH_KEY_ID}"]) {
                sh "ssh ${env.REMOTE_USER}@${env.REMOTE_HOST} 'bash -s' < ./deploy/rollback.sh ${params.ENV}"
            }
        }
    }
}
