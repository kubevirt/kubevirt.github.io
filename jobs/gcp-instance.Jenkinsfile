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
            parameterDefinitions: [                [
                    name: 'TARGET_NODE',
                    description: 'Jenkins agent node',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'gcloud'
                ],
                [
                    name: 'GCP_PROJECT',
                    description: 'The project ID for the GCP service account',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'cnvlab-209908'
                ],
                [
                    name: 'GCP_SERVICE_ACCOUNT',
                    description: 'The account ID (email) of the GCP service account',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt-io-testing@cnvlab-209908.iam.gserviceaccount.com'
                ],
                [
                    name: 'GCP_KEY_FILE',
                    description: 'The credential ID for the GCP service account key file',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'gcp-kubevirt-io-testing'
                ],
                [
                    name: 'GCP_ZONE',
                    description: 'Where to create the new instance',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'us-central1-b'
                ],
                [
                    name: 'GCP_INSTANCE_NAME',
                    description: 'The username to log into the VM instance',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt-demo-test'
                ],
                [
                    name: 'GCP_INSTANCE_USERNAME',
                    description: 'The username to log into the VM instance',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'centos'
                ],
                [
                    name: 'GCP_INSTANCE_PUBLIC_KEY_NAME',
                    description: 'The name of the Jenkins credentials containing the instance public key string',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'centos-public-key'
                ],
                [
                    name: 'GCP_INSTANCE_PRIVATE_KEY_NAME',
                    description: 'The name of the Jenkins credentials containing the instance public key string',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'centos-private-key'
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

    checkout scm

    stage("create instance") {
        echo "Creating instance"

        setup = build(
            job: 'gcp-setup',
            propagate: true,
            parameters: [
                [
                    name: 'TARGET_NODE',
                    value: TARGET_NODE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_PROJECT',
                    value: GCP_PROJECT,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_SERVICE_ACCOUNT',
                    value: GCP_SERVICE_ACCOUNT,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_KEY_FILE',
                    value: GCP_KEY_FILE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_ZONE',
                    value: GCP_ZONE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_INSTANCE_NAME',
                    value: GCP_INSTANCE_NAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_INSTANCE_USERNAME',
                    value: GCP_INSTANCE_USERNAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_INSTANCE_PUBLIC_KEY_NAME',
                    value: GCP_INSTANCE_PUBLIC_KEY_NAME,
                    $class: 'StringParameterValue',
                ],
                [
                    name: 'GCP_INSTANCE_PRIVATE_KEY_NAME',
                    value: GCP_INSTANCE_PRIVATE_KEY_NAME,
                    $class: 'StringParameterValue',
                ],                
                [
                    name: 'PERSIST',
                    value: true,
                    $class: 'BooleanParameterValue',
                ],
                [
                    name: 'DEBUG',
                    value: DEBUG,
                    $class: 'BooleanParameterValue',
                ]
            ]
        )

        currentBuild.displayName = "kubevirt-demos:${setup.displayName}"
        currentBuild.result = setup.result

    }

    stage("delete instance") {
        echo "Deleting instance"
        setup = build(
            job: 'gcp-teardown',
            propagate: true,
            parameters: [
                [
                    name: 'TARGET_NODE',
                    value: TARGET_NODE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_PROJECT',
                    value: GCP_PROJECT,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_SERVICE_ACCOUNT',
                    value: GCP_SERVICE_ACCOUNT,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_KEY_FILE',
                    value: GCP_KEY_FILE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_ZONE',
                    value: GCP_ZONE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'GCP_INSTANCE_NAME',
                    value: GCP_INSTANCE_NAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'PERSIST',
                    value: true,
                    $class: 'BooleanParameterValue',
                ],
                [
                    name: 'DEBUG',
                    value: DEBUG,
                    $class: 'BooleanParameterValue',
                ]
            ]
        )
    }
    
    if (!persist) {
        cleanWs()
        deleteDir()
    } 
}
