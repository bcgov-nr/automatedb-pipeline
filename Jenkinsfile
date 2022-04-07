pipeline {
    agent {
        label 'master'
    }
    environment {
        ENVIRONMENT = "???"
        cd_version = "???"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/jenkinsfile']],
                    doGenerateSubmoduleConfigurations: false,
                    gitTool: 'jgit',
                    submoduleCfg: [],
                    userRemoteConfigs: [
                        [
                            credentialsId: 'f1e16323-de75-4eac-a5a0-f1fc733e3621',
                            url: 'https://bwa.nrs.gov.bc.ca/int/stash/scm/oneteam/nr-liquibase.git'
                        ]
                    ]
                ])
            }
        }
        stage('Checkout DB') {
            steps {
                sh "# TODO"
            }
        }
        stage('Properties') {
            steps {
                sh "./scripts/properties.sh"
            }
        }
        stage('Update') {
            steps {
                sh "./scripts/update.sh"
            }
        }
    }
}