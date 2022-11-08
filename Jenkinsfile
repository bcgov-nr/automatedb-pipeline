pipeline {
    agent {
        label 'master'
    }
    environment {
        VAULT_ADDR = "https://vault-iit.apps.silver.devops.gov.bc.ca"
        BROKER_URL = "https://nr-broker.apps.silver.devops.gov.bc.ca"
        TARGET_ENV = "${params.environment}"
        GIT_REPO = "${params.gitRepo}"
        GIT_BRANCH = "${params.gitBranch}"
        SEM_VERSION = "${params.version}"
        TAG_VERSION = "v${SEM_VERSION}"
        PROJECT_KEY = "${params.project}"
        DB_COMPONENT = "${params.component}"
        BITBUCKET_BASEURL = "bwa.nrs.gov.bc.ca/int/stash"
        PODMAN_WORKDIR = "/liquibase/changelog"
        TMP_VOLUME = "liquibase.${UUID.randomUUID().toString()[0..7]}"
        PODMAN_REGISTRY = "docker.io"
        CONTAINER_IMAGE_CONSUL_TEMPLATE = "hashicorp/consul-template"
        CONTAINER_IMAGE_LIQUBASE = "liquibase/liquibase"
        CONTAINER_IMAGE_CURL = "curlimages/curl"
        HOST = "freight.bcgov"
        PODMAN_USER = "wwwadm"
        DB_ROLE_ID = "${params.roleId}"
        CONFIG_ROLE_ID = credentials('knox-vault-jenkins-isss-role-id')
        BASIC_HTTP_USER = "brokeruser"
        BASIC_HTTP_PASSWORD = credentials('nr-broker-password')
    }
    stages {
        stage('Setup') {
            steps {
                script {
                    env.CAUSE_USER_ID = getCauseUserId()
                    env.TARGET_ENV_SHORT = convertLongEnvToShort("${env.TARGET_ENV}")
                }
            }
        }
        stage('Get credentials') {
            steps {
                script {
                    env.INTENTION_JSON = sh(
                        returnStdout: true,
                        script: "set +x; scripts/broker_intention_open.sh scripts/intention-db.json"
                    )
                    env.CICD_VAULT_TOKEN = sh(
                        returnStdout: true,
                        script: "set +x; scripts/vault_cicd_token.sh"
                    )
                    env.APP_VAULT_TOKEN = sh(
                        returnStdout: true,
                        script: "set +x; scripts/vault_db_token.sh"
                    )
                    env.CD_USER = sh(
                        returnStdout: true,
                        script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$CICD_VAULT_TOKEN /sw_ux/bin/vault kv get -field=username_lowercase groups/appdelivery/jenkins-isss-cdua"
                    )
                    env.CD_PASS = sh(
                        returnStdout: true,
                        script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$CICD_VAULT_TOKEN /sw_ux/bin/vault kv get -field=password groups/appdelivery/jenkins-isss-cdua"
                    )
                    env.CI_USER = sh(
                        returnStdout: true,
                        script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$CICD_VAULT_TOKEN /sw_ux/bin/vault kv get -field=username_lowercase groups/appdelivery/jenkins-isss-ci"
                    )
                    env.CI_PASS = sh(
                        returnStdout: true,
                        script: "set +x; VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$CICD_VAULT_TOKEN /sw_ux/bin/vault kv get -field=password groups/appdelivery/jenkins-isss-ci"
                    )
                }
            }
        }
        stage('Check prod tag') {
            when { expression { return params.dryRun == false } }
            steps {
                script {
                    def rc = sh(
                        returnStatus: true,
                        script: "scripts/check_prod_tag.sh"
                    )
                    if (rc != 0) {
                        currentBuild.result = 'ABORTED'
                        error('Non-zero code returned during tag check. Stop execution.')
                    }
                }
            }
        }
        stage('Checkout for deployment to development') {
            when { environment name: 'TARGET_ENV', value: 'development' }
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "refs/heads/${GIT_BRANCH}"]],
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
        stage('Checkout for deployment to test') {
            when { environment name: 'TARGET_ENV', value: 'test' }
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "refs/tags/${TAG_VERSION}-development"]],
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
        stage('Checkout for deployment to production') {
            when { environment name: 'TARGET_ENV', value: 'production' }
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "refs/tags/${TAG_VERSION}-test"]],
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
        stage('Run Liquibase datafix select') {
            when { expression { return params.datafix == true } }
            steps {
                sh 'scripts/datafix_select.sh'
            }
        }
        stage('Run Liquibase dry run') {
            when { expression { return params.dryRun == true } }
            steps {
                sh 'scripts/update-dry-run.sh'
            }
        }
        stage('Run Liquibase') {
            when { expression { return params.dryRun == false } }
            steps {
                sh 'scripts/update.sh'
            }
        }
        stage('Test') {
            when { expression { return params.dryRun == false } }
            steps {
                sh 'echo Test changes'
            }
        }
        stage('Create tag') {
            when { expression { return params.dryRun == false } }
            steps {
                sh 'scripts/create_tag.sh'
            }
        }
    }
    post {
        success {
            sh "set +x; scripts/broker_intention_close.sh 'success'"
        }
        unstable {
            sh "set +x; scripts/broker_intention_close.sh 'failure'"
        }
        failure {
            sh "set +x; scripts/broker_intention_close.sh 'failure'"
        }
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

def getCauseUserId() {
    final hudson.model.Cause$UpstreamCause upstreamCause = currentBuild.rawBuild.getCause(hudson.model.Cause$UpstreamCause);
    final hudson.model.Cause$UserIdCause userIdCause = upstreamCause == null ?
        currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause) :
        upstreamCause.getUpstreamRun().getCause(hudson.model.Cause$UserIdCause);
    final String nameFromUserIdCause = userIdCause != null ? userIdCause.userId : null;
    if (nameFromUserIdCause != null) {
        return nameFromUserIdCause + "@idir";
    } else {
        return 'unknown'
    }
}

def convertLongEnvToShort(env) {
    envLongToShort = [:]
    envLongToShort["production"] = "prod"
    envLongToShort["test"] = "test"
    envLongToShort["development"] = "dev"
    return envLongToShort[env]
}
