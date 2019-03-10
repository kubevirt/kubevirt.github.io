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
                    name: 'OWNER_NUMBER',
                    description: "AWS Owner number",
                    $class: 'hudson.model.StringParameterDefinition'
                ],
                [
                    name: 'AWS_REGION',
                    $class: 'hudson.model.StringParameterDefinition',
                    description: 'AWS region',
                    defaultValue: 'us-east-1'
                ],
                [
                    name: 'AWS_CREDENTIALS',
                    $class: 'hudson.model.StringParameterDefinition',
                    description: 'AWS access credentials',
                    defaultValue: 'kubevirt-demos'
                ],
                [
                    name: 'INSTANCE_KEYPAIR_NAME',
                    description: "AWS SSH Keypair Name",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt-demos-ssh-name'
                ],
                [
                    name: 'INSTANCE_SSH_PRIVATE_KEY',
                    description: "Name of the SSH credentials for AWS instance",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt-demos-ssh'
                ],
                [
                    name: "INSTANCE_SSH_USERNAME",
                    description: "The username for SSH to the instance",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'centos'
                ],
                [
                    name: 'DEMO_NAME',
                    description: "The username for SSH to the instance",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'lab1'
                ],
                [
                    name: "DEMO_GIT_REPO",
                    description: "Where to find the demo page and test code",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: "https://github.com:kubevirt.github.io.git"
                ],
                [
                    name: "DEMO_GIT_BRANCH",
                    description: "The branch that contains the of the demo to run",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: "master"
                ],
                [
                    name: "DEMO_ROOT",
                    description: "The directory that contains the demo tests",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: '_includes/scriptlets'
                ],
                [
                    name: 'PERSIST',
                    description: 'leave the minikube service in place',
                    $class: 'hudson.model.BooleanParameterDefinition',
                    defaultValue: false
                ],
                [
                    name: 'DEBUG',
                    description: 'ask commands to print details',
                    $class: 'hudson.model.BooleanParameterDefinition',
                    defaultValue: false
                ]

            ]
        ]
    ]
)

persist = PERSIST.toBoolean()
debug = DEBUG.toBoolean()

node(TARGET_NODE) {

    sh "aws configure set region ${AWS_REGION}"

    stage("create instance") {
        setup = build(
            job: 'aws-setup',
            propagate: true,
            parameters: [
                [
                    name: 'TARGET_NODE',
                    value: TARGET_NODE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'OWNER_NUMBER',
                    value: OWNER_NUMBER,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'AWS_REGION',
                    value: AWS_REGION,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'AWS_CREDENTIALS',
                    value: AWS_CREDENTIALS,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_KEYPAIR_NAME',
                    value: INSTANCE_KEYPAIR_NAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_SSH_PRIVATE_KEY',
                    value: INSTANCE_SSH_PRIVATE_KEY,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_SSH_USERNAME',
                    value: INSTANCE_SSH_USERNAME,
                    $class: 'StringParameterValue'
                ]
            ]
        )
        currentBuild.displayName = "kubevirt-demos:${setup.displayName}"
        currentBuild.result = setup.result

        // grab the returned INSTANCE_ID from the build job variables
        AWS_INSTANCE_ID = setup.getBuildVariables().INSTANCE_ID
        AWS_INSTANCE_DNS_NAME = setup.getBuildVariables().INSTANCE_PUBLIC_DNS_NAME
    }

    stage("execute demo") {
        execute = build(
            job: "demo-test",
            propagate: true,
            parameters: [
                [
                    name: 'TARGET_NODE',
                    value: TARGET_NODE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_DNS_NAME',
                    value: AWS_INSTANCE_DNS_NAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_SSH_PRIVATE_KEY',
                    value: INSTANCE_SSH_PRIVATE_KEY,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_SSH_USERNAME',
                    value: INSTANCE_SSH_USERNAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'DEMO_NAME',
                    value: DEMO_NAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'DEMO_GIT_REPO',
                    value: DEMO_GIT_REPO,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'DEMO_GIT_BRANCH',
                    value: DEMO_GIT_BRANCH,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'DEMO_ROOT',
                    value: DEMO_ROOT,
                    $class: 'StringParameterValue'
                ]
            ]
        )

        copyArtifacts(
            projectName: 'demo-test',
            selector: specific("${execute.number}")
        )
    }
    
    stage("teardown instance") {

        echo "AWS_INSTANCE_ID = ${AWS_INSTANCE_ID}"

        teardown = build(
            job: 'aws-teardown',
            propagate: true,
            parameters: [
                [
                    name: 'TARGET_NODE',
                    value: TARGET_NODE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'AWS_CREDENTIALS',
                    value: AWS_CREDENTIALS,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'AWS_REGION',
                    value: AWS_REGION,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'AWS_INSTANCE_ID',
                    value: AWS_INSTANCE_ID,
                    $class: 'StringParameterValue'
                ]
            ]
        )
        currentBuild.result = teardown.result    
    }

    archiveArtifacts artifacts: "demo-test-result-*.txt"

    if (!persist) {
        cleanWs()
        deleteDir()
    } 
}
