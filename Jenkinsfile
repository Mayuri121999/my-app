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
                    cd my-app
                    npm install
                    npm run build
                '''
            }
        }


        // stage('Deploy') {
        //     steps {
        //         // sshagent (credentials: ["${env.SSH_KEY_ID}"]) {
        //         //     sh """
        //         //         scp -o StrictHostKeyChecking=no -r ./ ${env.REMOTE_USER}@${env.REMOTE_HOST}:${env.REMOTE_DIR}/releases/${params.DEPLOY_VERSION} "echo Connected to EC2"
        //         //         ssh ${env.REMOTE_USER}@${env.REMOTE_HOST} 'bash -s' < ./deploy/deploy.sh ${params.ENV} ${params.DEPLOY_VERSION}
        //         //     """
        //         // }


        //         withCredentials([sshUserPrivateKey(credentialsId: "${env.SSH_KEY_ID}", keyFileVariable: 'KEYFILE')]) {
        //             bat """
        //                 echo Using key: %KEYFILE%

        //                 REM Remove inheritance for strict permissions
        //                 icacls "%KEYFILE%" /inheritance:r

        //                 REM Grant Full Control to SYSTEM (adjust if your agent runs as a different user!)
        //                 icacls "%KEYFILE%" /grant:r "SYSTEM:F"

        //                 REM Verify file exists
        //                 dir "%KEYFILE%"

        //                 REM Copy the index.html
        //                 scp -o StrictHostKeyChecking=no -i "%KEYFILE%" index.html ${env.REMOTE_USER}@${env.REMOTE_HOST}:${env.REMOTE_DIR}/

        //                 REM Move to /var/www/html
        //                 ssh -o StrictHostKeyChecking=no -i "%KEYFILE%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "sudo mv ${env.REMOTE_DIR}/build/index.html /var/www/html/index.html"
        //             """
                
        //         }
        //     }
        // }
        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: "${env.SSH_KEY_ID}", keyFileVariable: 'KEYFILE')]) {
                    bat """
                        echo Using key: %KEYFILE%

                        REM ensure build exists
                        if not exist my-app\\build\\index.html (
                            echo Build output missing; aborting.
                            exit /b 1
                        )

                        REM prepare temp deploy directory on remote
                        ssh -o StrictHostKeyChecking=no -i "%KEYFILE%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "mkdir -p /home/${env.REMOTE_USER}/deploy_tmp"

                        REM copy new build to remote temp location
                        scp -o StrictHostKeyChecking=no -i "%KEYFILE%" -r my-app\\build\\* ${env.REMOTE_USER}@${env.REMOTE_HOST}:/home/${env.REMOTE_USER}/deploy_tmp/

                        REM perform atomic swap on remote: backup current, replace, reload nginx
                        ssh -o StrictHostKeyChecking=no -i "%KEYFILE%" ${env.REMOTE_USER}@${env.REMOTE_HOST} bash -s <<'ENDSSH'
                            set -e
                            TIMESTAMP=$(date +%Y%m%d%H%M%S)
                            NGINX_ROOT=/var/www/html
                            BACKUP_DIR=/home/${env.REMOTE_USER}/backup_$TIMESTAMP

                            echo "Backing up existing content..."
                            if [ -d "$NGINX_ROOT" ]; then
                                sudo cp -r "$NGINX_ROOT" "$BACKUP_DIR"
                            fi

                            echo "Clearing Nginx root..."
                            sudo rm -rf "$NGINX_ROOT"/*

                            echo "Copying new build into place..."
                            sudo cp -r /home/${env.REMOTE_USER}/deploy_tmp/* "$NGINX_ROOT"/

                            echo "Setting permissions..."
                            sudo chown -R www-data:www-data "$NGINX_ROOT"

                            echo "Reloading Nginx..."
                            sudo systemctl reload nginx

                            echo "Cleanup temp build"
                            rm -rf /home/${env.REMOTE_USER}/deploy_tmp/*
                        ENDSSH
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
