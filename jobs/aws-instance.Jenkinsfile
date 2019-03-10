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
                ]
            ]
        ]
    ]
)

node(TARGET_NODE) {

    sh "aws configure set region ${AWS_REGION}"

    stage("create instance") {
        setup = build(
            job: 'aws-setup',
            propagate: false,
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
    }

    stage("teardown instance") {

        sh "echo ${AWS_INSTANCE_ID}"
        
        teardown = build(
            job: 'aws-teardown',
            propagate: false,
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
}
