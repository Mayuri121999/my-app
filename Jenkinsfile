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

        // stage('Build') {
        //     steps {
        //         echo "In Build Stage"
        //         bat '''
        //             cd my-app
        //             npm install
        //             npm run build
        //             echo build done
        //         '''
        //     }
        // }

        stage('Build') {
            steps {
                echo "Building React app"
                bat '''
                    npm install
                    npm run build
                    echo build done
                '''
            }
        }


        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: "${env.SSH_KEY_ID}", keyFileVariable: 'KEYFILE')]) {
                    bat """
                        echo Using key: %KEYFILE%

                        REM tighten key permissions so OpenSSH will accept it
                        for /f "tokens=*" %%u in ('whoami') do set CURUSER=%%u
                        icacls "%KEYFILE%" /inheritance:r
                        icacls "%KEYFILE%" /grant:r "%CURUSER%:R"
                        icacls "%KEYFILE%" /grant:r "NT AUTHORITY\\SYSTEM:F"

                        REM ensure build exists
                        if not exist build\\index.html (
                            echo Build output missing; aborting.
                            exit /b 1
                        )

                        REM prepare remote temp dir
                        ssh -o StrictHostKeyChecking=no -i "%KEYFILE%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "mkdir -p /home/${env.REMOTE_USER}/deploy_tmp"

                        REM copy build to remote temp
                        scp -o StrictHostKeyChecking=no -i "%KEYFILE%" -r build\\* ${env.REMOTE_USER}@${env.REMOTE_HOST}:/home/${env.REMOTE_USER}/deploy_tmp/

                        REM invoke remote deploy script
                        ssh -o StrictHostKeyChecking=no -i "%KEYFILE%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "bash /home/ubuntu/deploy_simple.sh"
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
            // sshagent (credentials: ["${env.SSH_KEY_ID}"]) {
            //     sh "ssh ${env.REMOTE_USER}@${env.REMOTE_HOST} 'bash -s' < ./deploy/rollback.sh ${params.ENV}"
            // }
        }
    }
}
