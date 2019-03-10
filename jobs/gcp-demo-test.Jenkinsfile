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
        
        // grab the returned INSTANCE_ID from the build job variables
        GCP_INSTANCE_ID = setup.getBuildVariables().INSTANCE_ID
        GCP_INSTANCE_DNS_NAME = setup.getBuildVariables().INSTANCE_PUBLIC_DNS_NAME

    }

    stage("execute demo") {
        execute = build(
            job: "demo-test",
            propagate: false,
            parameters: [
                [
                    name: 'TARGET_NODE',
                    value: TARGET_NODE,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_DNS_NAME',
                    value: GCP_INSTANCE_DNS_NAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_SSH_PRIVATE_KEY',
                    value: GCP_INSTANCE_PRIVATE_KEY_NAME,
                    $class: 'StringParameterValue'
                ],
                [
                    name: 'INSTANCE_SSH_USERNAME',
                    value: GCP_INSTANCE_USERNAME,
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

    archive includes: "demo-test-result-*.txt"

    if (!persist) {
        cleanWs()
        deleteDir()
    } 
}
