pipeline {
    agent any

    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Run Liquibase Deployment') {
            steps {
                
                      // Add this debug block ↓↓↓
                sh '''
                  echo "WORKSPACE is: $WORKSPACE"
                  echo "Directory tree under workspace:"
                  ls -R .
                '''
                // End debug block ↑↑↑
                
                echo 'Running Liquibase Deployment Script...'
                sh 'chmod +x callLiquibaseDemoDeployment.sh'
                sh './callLiquibaseDemoDeployment.sh'
            }
        }
    }

    post {
        success {
            echo 'Liquibase deployment completed successfully!'
        }
        failure {
            echo 'Liquibase deployment failed!'
        }
    }
}
