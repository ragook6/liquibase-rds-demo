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
                echo 'Running Liquibase Deployment Script...'
                sh '/var/lib/jenkins/callLiquibaseDemoDeployment.sh'
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
