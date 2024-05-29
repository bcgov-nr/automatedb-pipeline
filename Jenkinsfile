@Library('polaris')
import ca.bc.gov.nrids.polaris.BrokerIntention
import ca.bc.gov.nrids.polaris.JenkinsUtil
import ca.bc.gov.nrids.polaris.Podman
import ca.bc.gov.nrids.polaris.Vault

def intention

pipeline {
    agent {
        label Podman.AGENT_LABEL_APP
    }
    environment {
        PATH = "/sw_ux/bin:$PATH"
        VAULT_ADDR = "https://knox.io.nrs.gov.bc.ca"
        BROKER_URL = "https://broker.io.nrs.gov.bc.ca"
        TARGET_ENV = "${params.environment}"
        GH_REPO = "${params.githubRepo}"
        OWNER = GH_REPO.substring(0, GH_REPO.lastIndexOf("/"))
        REPO = GH_REPO.substring(GH_REPO.lastIndexOf("/") + 1)
        GIT_BRANCH = "${params.gitBranch}"
        SEM_VERSION = "${params.semanticVersion}"
        TAG_VERSION = "v${SEM_VERSION}"
        SERVICE_PROJECT = "${params.serviceProject}"
        SERVICE_NAME = "${params.serviceName}"
        PODMAN_WORKDIR = "/liquibase/changelog"
        TMP_VOLUME = "liquibase.${UUID.randomUUID().toString()[0..7]}"
        TMP_OUTPUT_FILE = "liquibase.stderr.${UUID.randomUUID().toString()[0..7]}"
        ONFAIL_GREP_PATTERN = "^WARNING"
        NOTIFICATION_RECIPIENTS = "${params.notificationRecipients}"
        EVENT_PROVIDER = "${params.eventProvider}"
        PODMAN_REGISTRY = "docker.io"
        CONTAINER_IMAGE_CONSUL_TEMPLATE = "hashicorp/consul-template"
        CONTAINER_IMAGE_LIQUBASE = "liquibase/liquibase"
        HOST = "freight.bcgov"
        PODMAN_USER = "wwwadm"
        DB_ROLE_ID = "${params.dbRoleId}"
        CONFIG_ROLE_ID = credentials('knox-jenkins-jenkins-apps-prod-role-id')
        GH_APP_ROLE_ID = "${params.ghAppRoleId}"
        NR_BROKER_TOKEN = credentials('nr-broker-jwt')
        AUTHFILE = "auth.json"
    }
    stages {
        stage('Setup') {
            steps {
                script {
                    env.CAUSE_USER_ID = JenkinsUtil.getUpstreamCauseUserId(currentBuild)
                    env.TARGET_ENV_SHORT = JenkinsUtil.convertLongEnvToShort("${env.TARGET_ENV}")
                }
            }
        }
        stage('Get github token') {
            steps {
                script {
                    // open intention to get github app creds
                    intention = new BrokerIntention(readJSON(file: 'scripts/intention-github.json'))
                    intention.setEventDetails(
                        userName: env.CAUSE_USER_ID,
                        provider: env.EVENT_PROVIDER,
                        url: env.BUILD_URL,
                        serviceName: env.SERVICE_NAME,
                        serviceProject: env.SERVICE_PROJECT,
                        environment: "production"
                    )
                    intention.open(NR_BROKER_TOKEN)
                    intention.startAction("login")
                    def vaultGhToken = intention.provisionToken("login", GH_APP_ROLE_ID)
                    def vaultGhApp = new Vault(vaultGhToken)
                    def ghAppCreds = vaultGhApp.read("apps/data/prod/${SERVICE_PROJECT}/${SERVICE_NAME}/github_app")
                    env.APP_ID = ghAppCreds['app_id']
                    env.INSTALLATION_ID = ghAppCreds['installation_id']
                    env.PRIVATE_KEY = ghAppCreds['private_key']
                    // generate github app jwt
                    env.GENERATED_JWT = sh(
                        returnStdout: true,
                        script: 'set +x; scripts/generate_jwt.sh'
                    )
                    env.GH_TOKEN = sh(
                        returnStdout: true,
                        script: 'set +x; scripts/get_installation_token.sh'
                    )
                    intention.endAction("login")
                    intention.close(true)
                }
            }
        }
        stage('Check prod release') {
            when { expression { return params.dryRun == false } }
            steps {
                script {
                    def rc = sh(
                        returnStatus: true,
                        script: "set +x; GH_TOKEN=${GH_TOKEN} gh api repos/${OWNER}/${REPO}/releases/tags/${TAG_VERSION}"
                    )
                    if (OWNER != null && OWNER != "" && REPO != null && REPO != "" && rc == 0) {
                        currentBuild.result = 'ABORTED'
                        error('Release check error')
                    }
                }
            }
        }
        stage('Checkout for deployment to development') {
            when { environment name: 'TARGET_ENV', value: 'development' }
            steps {
                script {
                    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[var: env.GH_TOKEN, password: GH_TOKEN]]]) {
                        sh "GH_TOKEN=${GH_TOKEN} gh repo clone ${OWNER}/${REPO} ${TMP_VOLUME} -- --branch=${GIT_BRANCH}"
                    }
                }
            }
        }
        stage('Checkout for deployment to test') {
            when { environment name: 'TARGET_ENV', value: 'test' }
            steps {
                script {
                    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[var: env.GH_TOKEN, password: GH_TOKEN]]]) {
                        sh "GH_TOKEN=${GH_TOKEN} gh repo clone ${OWNER}/${REPO} ${TMP_VOLUME} -- --branch=${TAG_VERSION}-development"
                    }
                }
            }
        }
        stage('Checkout for deployment to production') {
            when { environment name: 'TARGET_ENV', value: 'production' }
            steps {
                script {
                    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[var: env.GH_TOKEN, password: GH_TOKEN]]]) {
                        sh "GH_TOKEN=${GH_TOKEN} gh repo clone ${OWNER}/${REPO} ${TMP_VOLUME} -- --branch=${TAG_VERSION}-test"
                    }
                }
            }
        }
        stage('Generate Liquibase properties') {
            steps {
                script {
                    // open intention to get registry and db creds
                    intention = new BrokerIntention(readJSON(file: 'scripts/intention-db.json'))
                    intention.setEventDetails(
                        userName: env.CAUSE_USER_ID,
                        provider: env.EVENT_PROVIDER,
                        url: env.BUILD_URL,
                        serviceName: env.SERVICE_NAME,
                        serviceProject: env.SERVICE_PROJECT,
                        environment: env.TARGET_ENV
                    )
                    intention.open(NR_BROKER_TOKEN)
                    intention.startAction("login")
                    def vaultToken = intention.provisionToken("login", CONFIG_ROLE_ID)
                    def vault = new Vault(vaultToken)
                    def registryCreds = vault.read('apps/data/prod/jenkins/jenkins-apps/artifactory')
                    env.REGISTRY_USERNAME = registryCreds['REGISTRY_USERNAME']
                    env.REGISTRY_PASSWORD = registryCreds['REGISTRY_PASSWORD']
                    env.APP_VAULT_TOKEN = intention.provisionToken("database", DB_ROLE_ID)
                    podman = new Podman(this, null)
                    podman.login(authfile: "${TMP_VOLUME}/${AUTHFILE}", options: "-u ${env.REGISTRY_USERNAME} -p ${env.REGISTRY_PASSWORD}")
                    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[var: env.APP_VAULT_TOKEN, password: APP_VAULT_TOKEN]]]) {
                        podman.run("${CONTAINER_IMAGE_CONSUL_TEMPLATE}",
                            authfile: "${TMP_VOLUME}/${AUTHFILE}",
                            options: "--rm \
                                --security-opt label=disable \
                                --userns keep-id \
                                -v \$(pwd)/${TMP_VOLUME}:${PODMAN_WORKDIR} \
                                -v \$(pwd)/scripts/config.hcl:${PODMAN_WORKDIR}/config.hcl \
                                -e TARGET_ENV_SHORT=${env.TARGET_ENV_SHORT} \
                                -e PODMAN_WORKDIR=${PODMAN_WORKDIR} \
                                -e VAULT_TOKEN=${APP_VAULT_TOKEN}",
                            command: "-config '/liquibase/changelog/config.hcl' \
                                -template '/liquibase/changelog/liquibase.properties.tpl:${PODMAN_WORKDIR}/liquibase.properties' \
                                -once",
                            returnStatus: true
                        )
                    }
                    intention.endAction("login")
                }
            }
        }
        stage('Run Liquibase datafix select') {
            when {
                anyOf {
                    expression { return params.datafix == true }
                    expression { return params.datacheck == true }
                }
            }
            steps {
                script {
                    intention.startAction("database")
                    podman.run("${CONTAINER_IMAGE_LIQUBASE}",
                        authfile: "${TMP_VOLUME}/${AUTHFILE}",
                        options: "--rm \
                            --security-opt label=disable \
                            --userns keep-id \
                            -v \$(pwd)/${TMP_VOLUME}:${PODMAN_WORKDIR} \
                            --workdir ${PODMAN_WORKDIR}",
                        command: "--defaultsFile=liquibase.properties --sql-file=scripts/datafix_select.sql execute-sql"
                    )
                }
            }
        }
        stage('Run Liquibase dry run') {
            when { expression { return params.dryRun == true } }
            steps {
                script {
                    podman.run("${CONTAINER_IMAGE_LIQUBASE}",
                        authfile: "${TMP_VOLUME}/${AUTHFILE}",
                        options: "--rm \
                            --security-opt label=disable \
                            --userns keep-id \
                            -v \$(pwd)/${TMP_VOLUME}:${PODMAN_WORKDIR} \
                            --workdir ${PODMAN_WORKDIR}",
                        command: "--defaultsFile=liquibase.properties update-sql"
                    )
                }
            }
        }
        stage('Run Liquibase') {
            when { expression { return params.dryRun == false } }
            steps {
                script {
                    podman.run("${CONTAINER_IMAGE_LIQUBASE}",
                        authfile: "${TMP_VOLUME}/${AUTHFILE}",
                        options: "--rm \
                            --security-opt label=disable \
                            --userns keep-id \
                            -v \$(pwd)/${TMP_VOLUME}:${PODMAN_WORKDIR} \
                            --workdir ${PODMAN_WORKDIR}",
                        command: "--defaultsFile=liquibase.properties update 2> ${TMP_OUTPUT_FILE}"
                    )
                    // extract message and send notification
                    sh """
                        ONFAIL_WARNING_COUNT="\$(grep '${ONFAIL_GREP_PATTERN}' ${TMP_OUTPUT_FILE} | wc -l)"
                        if [ \$ONFAIL_WARNING_COUNT -gt 0 ] && [ "$TARGET_ENV" = "production" ]; then
                            ONFAIL_MESSAGE="\$(sed -n '/${ONFAIL_GREP_PATTERN}/{N;p}' ${TMP_OUTPUT_FILE})"
                            printf "${BUILD_URL}\n\n\${ONFAIL_MESSAGE}" | mailx -s "Data quality issue detected" "${NOTIFICATION_RECIPIENTS}"
                        fi
                    """
                    // tag version in liquibase
                    podman.run("${CONTAINER_IMAGE_LIQUBASE}",
                        authfile: "${TMP_VOLUME}/${AUTHFILE}",
                        options: "--rm \
                            --security-opt label=disable \
                            --userns keep-id \
                            -v \$(pwd)/${TMP_VOLUME}:${PODMAN_WORKDIR} \
                            --workdir ${PODMAN_WORKDIR}",
                        command: "--defaultsFile=liquibase.properties tag ${TAG_VERSION}"
                    )
                    intention.endAction("database")
                    podman.logout(authfile: "${TMP_VOLUME}/${AUTHFILE}")
                }
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
                script {
                    // set tag name and get commit id
                    if (TARGET_ENV == 'development') {
                        env.TAG_NAME = "${TAG_VERSION}-development"
                        env.COMMIT_ID = sh(
                            returnStdout: true,
                            script: "set +x; GH_TOKEN=${GH_TOKEN} gh api repos/${OWNER}/${REPO}/commits/heads/main --jq '.sha'"
                        ).trim()
                    }
                    if (TARGET_ENV == 'test') {
                        env.TAG_NAME = "${TAG_VERSION}-test"
                        env.COMMIT_ID = sh(
                            returnStdout: true,
                            script: "set +x; GH_TOKEN=${GH_TOKEN} gh api repos/${OWNER}/${REPO}/git/refs/tags/${TAG_VERSION}-development --jq '.object.sha'"
                        ).trim()
                    }
                    if (TARGET_ENV == 'production') {
                        env.TAG_NAME = "${TAG_VERSION}"
                        env.COMMIT_ID = sh(
                            returnStdout: true,
                            script: "set +x; GH_TOKEN=${GH_TOKEN} gh api repos/${OWNER}/${REPO}/git/refs/tags/${TAG_VERSION}-test --jq '.object.sha'"
                        ).trim()
                    }
                    // delete non-production tags
                    def rc = sh(
                        returnStatus: true,
                        script: "set +x; GH_TOKEN=${GH_TOKEN} gh api repos/${OWNER}/${REPO}/git/refs/tags/${TAG_NAME} --silent"
                    )
                    if ((TARGET_ENV == 'development' || TARGET_ENV == 'test') && rc == 0) {
                        wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[var: env.GH_TOKEN, password: GH_TOKEN]]]) {
                            sh "GH_TOKEN=${GH_TOKEN} gh api --method DELETE repos/${OWNER}/${REPO}/git/refs/tags/${TAG_NAME}"
                        }
                    }
                    // create new non-production tag
                    if (TARGET_ENV == 'development' || TARGET_ENV == 'test') {
                        wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[var: env.GH_TOKEN, password: GH_TOKEN]]]) {
                            sh "GH_TOKEN=${GH_TOKEN} gh api repos/${OWNER}/${REPO}/git/refs -f 'ref=refs/tags/${TAG_NAME}' -f 'sha=${COMMIT_ID}'"
                        }
                    }
                    // create production release
                    if (TARGET_ENV == 'production') {
                        wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[var: env.GH_TOKEN, password: GH_TOKEN]]]) {
                            sh "GH_TOKEN=${GH_TOKEN} gh api repos/${OWNER}}/${REPO}/releases -f 'tag_name=${TAG_NAME}' -F 'generate_release_notes=true'"
                        }
                    }
                }
            }
        }
    }
    post {
        success {
            node(Podman.AGENT_LABEL_APP) {
                script {
                    if (intention) {
                        println intention.close(true)
                    }
                }
            }
        }
        unstable {
            node(Podman.AGENT_LABEL_APP) {
                script {
                    if (intention) {
                        println intention.close(false)
                    }
                }
            }
        }
        failure {
            node(Podman.AGENT_LABEL_APP) {
                script {
                    if (intention) {
                        println intention.close(false)
                    }
                }
            }
        }
        aborted {
            node(Podman.AGENT_LABEL_APP) {
                script {
                    if (intention) {
                        println intention.close(false)
                    }
                }
            }
        }
        always {
            node(Podman.AGENT_LABEL_APP) {
                cleanWs(
                    cleanWhenAborted: true,
                    cleanWhenFailure: false,
                    cleanWhenSuccess: true,
                    cleanWhenUnstable: false,
                    deleteDirs: true
                )
            }
        }
    }
}
