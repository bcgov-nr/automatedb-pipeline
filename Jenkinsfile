pipeline {
    agent {
        label 'master'
    }
    environment {
        VAULT_ADDR = "https://vault-iit.apps.silver.devops.gov.bc.ca"
        VAULT_TOKEN = "${params.vaultToken}"
        ENVIRONMENT = "${params.environment}"
        cd_version = "${params.cd_version}"
    }
    stages {
        stage('Checkout DB') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: 'fb']
                    ]
                    submoduleCfg: [],
                    userRemoteConfigs: [
                        [
                            credentialsId: 'f1e16323-de75-4eac-a5a0-f1fc733e3621',
                            url: 'https://bwa.nrs.gov.bc.ca/int/stash/scm/oneteam/nr-liquibase-template-db.git'
                        ]
                    ]
                ])
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