pipeline {

    agent any

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Repository Audit') {
            steps {
                sh '''
                echo "Workspace : $WORKSPACE"
                echo "Commit    : $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
                ls -la
                '''
            }
        }

        stage('Set Script Permissions') {
            steps {
                sh 'chmod -R +x scripts/bash/'
            }
        }

        stage('Validate Environment') {
            steps {
                sh './scripts/bash/postgresql/validate_environment.sh'
            }
        }

        stage('Generate Datasets') {
            steps {
                sh 'python3 scripts/python/postgresql/generate_dataset.py'
            }
        }

        stage('Validate CSV Schema') {
            steps {
                sh 'python3 scripts/python/postgresql/testcsvschema.py'
            }
        }

        stage('Load Data') {
            steps {
                sh './scripts/bash/postgresql/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/postgresql/validate_loaded_data.sh'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/validate_postgresql.sh'
            }
        }

    }

    post {
        success {
            echo 'UBUNTU POSTGRESQL LOAD SUCCESSFUL'
        }
        failure {
            echo 'UBUNTU POSTGRESQL LOAD FAILED'
        }
        always {
            echo 'UBUNTU POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}