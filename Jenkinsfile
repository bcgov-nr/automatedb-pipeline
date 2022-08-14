pipeline {
    agent {
        label 'master'
    }
    environment {
        VAULT_ADDR = "https://vault-iit.apps.silver.devops.gov.bc.ca"
        FLUENTBIT_DEPLOYER_TOKEN = credentials('fluentbit-deployer')
        VAULT_TOKEN = """${sh(
                returnStdout: true,
                script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$FLUENTBIT_DEPLOYER_TOKEN /sw_ux/bin/vault token create \
                    -ttl=60 -explicit-max-ttl=60 -renewable=false -field=token -policy=system/isss-cdua-read"
            )}"""
        APP_VAULT_TOKEN = "${params.wrappingToken}"
        TARGET_ENV = "${params.environment}"
        GIT_REPO = "${params.gitRepo}"
        GIT_BRANCH = "${params.gitBranch}"
        TAG_VERSION = "${params.version}"
        WORKDIR = "${params.workdir}"
        TMP_VOLUME = "liquibase.${UUID.randomUUID().toString()[0..7]}"
        PODMAN_REGISTRY = "docker.io"
        CONTAINER_IMAGE_CONSUL_TEMPLATE = "hashicorp/consul-template"
        CONTAINER_IMAGE_LIQUBASE = "liquibase/liquibase"
        HOST = "freight.bcgov"
        PODMAN_USER = "wwwadm"
    }
    stages {
        stage('Get credentials') {
            steps {
                script {
                    env.CD_USER = sh(
                        returnStdout: true,
                        script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault kv get -field=username_lowercase groups/appdelivery/jenkins-isss-cdua"
                    )
                    env.CD_PASS = sh(
                        returnStdout: true,
                        script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN /sw_ux/bin/vault kv get -field=password groups/appdelivery/jenkins-isss-cdua"
                    )
                }
            }
        }
        stage('Checkout DB') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: "${TMP_VOLUME}"]
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
        stage('Copy files to server') {
            steps {
                sh 'scripts/copy.sh'
            }
        }
        stage('Generate Liquibase properties') {
            steps {
                sh 'scripts/properties.sh'
            }
        }
        stage('Run Liquibase') {
            steps {
                sh 'scripts/update.sh'
            }
        }
    }
    post {
        always {
            // clean up server temp directory
            sh "scripts/cleanup.sh"
            // clean up workspace temp directories
            dir("${TMP_VOLUME}") {
                deleteDir()
            }
            dir("${TMP_VOLUME}@tmp") {
                deleteDir()
            }
            dir("${TMP_VOLUME}@script") {
                deleteDir()
            }
            dir("${TMP_VOLUME}@script@tmp") {
                deleteDir()
            }
        }
    }
}
