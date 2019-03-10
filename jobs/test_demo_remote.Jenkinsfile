#!/usr/bin/env groovy

properties(
    [
        buildDiscarder(
            logRotator(
                artifactDaysToKeepStr: '',
                artifactNumToKeepStr: '',
                daysToKeepStr: '',
                numToKeepStr: '5')),
        [
            $class: 'ParametersDefinitionProperty',
            parameterDefinitions: [
                [
                    name: 'TARGET_NODE',
                    description: 'Jenkins agent node',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'awscli'
                ],
                [
                    name: "DEMO_NAME",
                    description: "The name of the demo to run",
                    $class: 'hudson.model.StringParameterDefinition',
                ],
                [
                    name: 'INSTANCE_DNS_NAME',
                    description: "Name of host to execute the demo",
                    $class: 'hudson.model.StringParameterDefinition',
                ],
                [
                    name: 'INSTANCE_SSH_PRIVATE_KEY',
                    description: "Name of the SSH credentials for instance",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt-demos-ssh'
                ],
                [
                    name: "INSTANCE_SSH_USERNAME",
                    description: "The username for SSH to the instance",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'centos'
                ]
            ]
        ]
    ]
)

SSH_HOST_SPEC = "${INSTANCE_SSH_USERNAME}@${INSTANCE_DNS_NAME}"
SSH_OPTIONS = "-o StrictHostKeyChecking=no"
SSH = "ssh ${SSH_OPTIONS} ${SSH_HOST_SPEC}"
SCP = "scp ${SSH_OPTIONS}"

node(TARGET_NODE) {

    checkout scm
    
    sshagent([INSTANCE_SSH_PRIVATE_KEY]) {

        stage('push demo test script') {
            echo "pushing demo test script"
            sh "${SSH} mkdir -p bin demos"
            sh "${SCP} scripts/run_script.py ${SSH_HOST_SPEC}:bin"
            sh "${SSH} chmod a+x bin/\\*"
        }

        stage('configure kubectl') {
            echo "configure kubectl on remote"
            // return the status to avoid error on no-create
            cmd_status = sh(
                returnStatus: true,
                script: "${SSH} 'mkdir -p ~/.kube ; [ -r ./admin.conf -a ! -r .kube/config ] && ln -s ~/admin.conf .kube/config'"
            )

            // sh "${SCP} localfile ${SSH_HOST_SPEC}:dest"
            // sh "${SSH} chmod a+x bin/\*"
        }

        stage('push demo files') {
            echo "push demo files"
            sh "${SCP} -r _includes/scriptlets/${DEMO_NAME} ${SSH_HOST_SPEC}:demos/"
        }

        stage("execute test") {
            echo "execute test"
            result = sh (
                returnStdout: true,
                script: "${SSH} bin/run_script.py -t demos/${DEMO_NAME}"
            )
            echo "result = --- \n${result}\n---"
            
            writeFile(
                file: "demo-test-result-${demo_name}.txt",
                text: "${result}"
            )
        }
    }


    archive includes: "demo-test-result-*.txt"
}
