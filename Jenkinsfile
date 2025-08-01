pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_VERSION', defaultValue: 'v1.0.0', description: 'Version for this deployment')
        string(name: 'BRANCH_NAME', defaultValue: 'dev', description: 'Git branch to deploy')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    }

    environment {
        SSH_KEY_ID = 'ec2-ssh-key'               // Jenkins SSH credential ID (SSH Username with private key)
        REMOTE_USER = 'ubuntu'
        REMOTE_HOST = '51.20.181.213'
        REMOTE_DIR = '/home/ubuntu/my-app'
        PORT = '3000'
    }

    tools {
        nodejs 'node-version' // must match what you configured in Jenkins global tools
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
        //         withCredentials([sshUserPrivateKey(credentialsId: "${env.SSH_KEY_ID}", keyFileVariable: 'KEYFILE')]) {
        //             bat """
        //                 echo === Deploying to EC2 ===
        //                 echo Using original key: %KEYFILE%

        //                 REM copy key to a controlled temp file to tighten permissions
        //                 set USED_KEY=%TEMP%\\\\jenkins_deploy_key.pem
        //                 copy "%KEYFILE%" "%USED_KEY%" /Y >nul

        //                 REM remove inherited ACLs and give current user read access
        //                 icacls "%USED_KEY%" /inheritance:r
        //                 icacls "%USED_KEY%" /grant:r "%USERNAME%:R"

        //                 REM (optional) if Jenkins runs as SYSTEM and needs it:
        //                 icacls "%USED_KEY%" /grant:r "NT AUTHORITY\\\\SYSTEM:F"

        //                 REM verify build exists
        //                 if not exist my-app\\build\\index.html (
        //                     echo Build output missing; aborting.
        //                     exit /b 1
        //                 )

        //                 REM create remote temp folder for staging
        //                 ssh -o StrictHostKeyChecking=no -i "%USED_KEY%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "mkdir -p /home/${env.REMOTE_USER}/deploy_tmp"

        //                 REM copy the build content to remote temp
        //                 scp -o StrictHostKeyChecking=no -i "%USED_KEY%" -r my-app\\build\\* ${env.REMOTE_USER}@${env.REMOTE_HOST}:/home/${env.REMOTE_USER}/deploy_tmp/

        //                 REM invoke remote deploy script (make sure it's executable on EC2)
        //                 ssh -o StrictHostKeyChecking=no -i "%USED_KEY%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "chmod +x ${env.REMOTE_DIR}/deploy/deploy.sh && bash ${env.REMOTE_DIR}/deploy/deploy.sh ${params.ENV} ${params.DEPLOY_VERSION}"
        //             """
        //         }
        //     }
        // }

        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: "${env.SSH_KEY_ID}", keyFileVariable: 'KEYFILE')]) {
                    bat """
                        echo === Deploying to EC2 ===
                        echo Using key from Jenkins credentials

                        REM copy key to a temp path so we don't touch the original
                        set USED_KEY=%TEMP%\\\\jenkins_deploy_key.pem
                        copy "%KEYFILE%" "%USED_KEY%" /Y >nul

                        REM verify build exists
                        if not exist my-app\\build\\index.html (
                            echo Build output missing; aborting.
                            exit /b 1
                        )

                        REM prepare remote staging directory
                        ssh -o StrictHostKeyChecking=no -i "%USED_KEY%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "mkdir -p /home/${env.REMOTE_USER}/deploy_tmp"

                        REM copy build artifacts
                        scp -o StrictHostKeyChecking=no -i "%USED_KEY%" -r my-app\\build\\* ${env.REMOTE_USER}@${env.REMOTE_HOST}:/home/${env.REMOTE_USER}/deploy_tmp/

                        REM run remote deploy script
                        ssh -o StrictHostKeyChecking=no -i "%USED_KEY%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "chmod +x ${env.REMOTE_DIR}/deploy/deploy.sh && bash ${env.REMOTE_DIR}/deploy/deploy.sh ${params.ENV} ${params.DEPLOY_VERSION}"
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                bat """
                    powershell -Command ^
                      try { ^
                        $resp = Invoke-WebRequest -UseBasicParsing http://${env.REMOTE_HOST}:${env.PORT} -TimeoutSec 10; ^
                        if ($resp.StatusCode -ne 200) { throw 'Health check failed'; } else { Write-Output 'Health check passed'; } ^
                      } catch { Write-Error 'Health check failed'; exit 1 }
                """
            }
        }
    }

    post {
        failure {
            echo "Deployment failed. Rolling back..."
            withCredentials([sshUserPrivateKey(credentialsId: "${env.SSH_KEY_ID}", keyFileVariable: 'KEYFILE')]) {
                bat """
                    REM prepare key copy again for rollback
                    set USED_KEY=%TEMP%\\\\jenkins_rollback_key.pem
                    copy "%KEYFILE%" "%USED_KEY%" /Y >nul
                    icacls "%USED_KEY%" /inheritance:r
                    icacls "%USED_KEY%" /grant:r "%USERNAME%:R"

                    ssh -o StrictHostKeyChecking=no -i "%USED_KEY%" ${env.REMOTE_USER}@${env.REMOTE_HOST} "bash ${env.REMOTE_DIR}/rollback.sh ${params.ENV}"
                """
            }
        }
    }
}
