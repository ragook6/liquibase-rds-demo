pipeline {
    agent any

    parameters {
        choice(
            name: 'LB_ACTION',
            choices: ['update', 'rollback'],
            description: 'Choose Liquibase action: update (deploy) or rollback last changeSet'
        )
    }

    environment {
        // Expose the parameter to the shell script
        LB_ACTION = "${params.LB_ACTION}"
    }

    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Run Liquibase') {
            steps {
                sh '''
                  echo "WORKSPACE is: $WORKSPACE"
                  echo "Directory tree under workspace:"
                  ls -R .
                '''
                echo "Running Liquibase with ACTION=${LB_ACTION}..."
                sh 'chmod +x callLiquibaseDemoDeployment.sh'
                sh './callLiquibaseDemoDeployment.sh'
            }
        }
    }

    post {
        success {
            echo "Liquibase ${env.LB_ACTION} completed successfully!"
        }
        failure {
            echo "Liquibase ${env.LB_ACTION} failed!"
        }
    }
}
