pipeline {
    agent {
        label 'master'
    }
    environment {
        PATH = "/sw_ux/node/current/bin:/sw_ux/bin:$PATH"
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
        stage('Properites') {
            steps {
                sh "./properties.sh"
            }
        }
        stage('Verify') {
            steps {
                sh "./verify.sh"
            }
        }
        stage('Update') {
            steps {
                sh "./update.sh"
            }
        }
    }
}