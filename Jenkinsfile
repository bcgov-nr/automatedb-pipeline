pipeline {
    agent {
        label 'master'
    }
    environment {
        VAULT_ADDR = "https://vault-iit.apps.silver.devops.gov.bc.ca"
        WRAPPING_TOKEN = "${params.wrappingToken}"
        CD_CREDS = credentials('dfe40532-f346-423c-bd6f-6c65d23bc422')
        CD_USER = "${CD_CREDS_USR}"
        CD_PASS = "${CD_CREDS_PSW}"
        ENVIRONMENT = "${params.environment}"
        GIT_REPO = "${params.gitRepo}"
        GIT_BRANCH = "${params.gitBranch}"
        VERSION = "${params.version}"
        TMP_DIR = "liquibase.${UUID.randomUUID().toString()[0..7]}"
        HOST = "freight.bcgov"
        INSTALL_USER = "wwwadm"
        VAULT_TOKEN = """${sh(
                returnStdout: true,
                script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$WRAPPING_TOKEN /sw_ux/bin/vault unwrap -field=token"
            )}"""
    }
    stages {
        stage('Checkout DB') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: "${TMP_DIR}"]
                    ],
                    submoduleCfg: [],
                    userRemoteConfigs: [
                        [
                            credentialsId: 'f1e16323-de75-4eac-a5a0-f1fc733e3621',
                            url: "${GIT_REPO}"
                        ]
                    ]
                ])
            }
        }
        stage('Generate Liquibase properties') {
            steps {
                sh 'scripts/properties.sh'
            }
        }
        stage('Copy deployment files to server') {
            steps {
                sh 'scripts/copy.sh'
            }
        }
        stage('Run Liquibase') {
            steps {
                sh 'scripts/run.sh'
            }
        }
    }
    post {
        always {
            // clean up server temp directory
            sh "scripts/cleanup.sh"
            // clean up workspace temp directories
            dir("${TMP_DIR}") {
                deleteDir()
            }
            dir("${TMP_DIR}@tmp") {
                deleteDir()
            }
            dir("${TMP_DIR}@script") {
                deleteDir()
            }
            dir("${TMP_DIR}@script@tmp") {
                deleteDir()
            }
        }
    }
}
