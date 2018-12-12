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
                    name: 'KUBEVIRT_HOSTNAME',
                    description: 'Hostname of the kubevirt server',
                    $class: 'hudson.model.StringParameterDefinition'
                ],
                [
                    name: 'PERSIST',
                    description: "If true, leave test artifacts on the host",
                    $class: 'hudson.model.BooleanParameterDefinition',
                    default: false
                ]
            ]
        ]
    ]
)

persist = PERSIST.toBoolean()

def remote(command) { sh "ssh centos@${KUBEVIRT_HOSTNAME} ${command}" }

node(TARGET_NODE) {
        
    sshagent(['kubevirt-centos']) {

        stage("setup lab 1") {
            echo "lab 1: setup"
            sh "git clone --branch scriptlets https://github.com/markllama/kubevirt.github.io.git"

            sh(
                script: "scp -r kubevirt.github.io/_includes/scriptlets/lab1 centos@${KUBEVIRT_HOSTNAME}:demo"
            )
            sh(
                script: "scp -r kubevirt.github.io/scripts/test_demo.sh  centos@${KUBEVIRT_HOSTNAME}:"
            )
        }

        stage("run lab 1") {
            echo "lab 1: begin"
            remote "ls demo"
            echo "lab 1: end"
        }

        stage("clean up lab 1") {
            if (persist) {
                echo "lab1: leave side effects in place"
            } else {
                echo "lab1: teardown"
                remote "rm -rf demo"
            }
        }
    }

    // cleanup workspace
    deleteDir()
}
