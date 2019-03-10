#!/usr/bin/env groovy

@Library('awscli')
import com.redhat.gcloud.*;

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

def gcloud_login_service_account(String project, String username, String keyfile) {
    sh "gcloud config set project ${project}"
    sh "gcloud auth activate-service-account '${username}' --key-file='${keyfile}'"
}

node(TARGET_NODE) {

    checkout scm

    withCredentials(
        [
            file(credentialsId: GCP_KEY_FILE, variable: 'gcp_key_file'),
        ]
    ) {
        
        stage('Configure gcloud auth') {
            echo "Configuring gcloud auth"
            gcloud_login_service_account(GCP_PROJECT, GCP_SERVICE_ACCOUNT, gcp_key_file)
        }

        stage('get instance by name') {
            echo "Retrieve the instance data by name"

            query_instance = Instance.queryByName(GCP_INSTANCE_NAME, GCP_ZONE, this)
            echo "instance_name: ${query_instance.name}, instance id: ${query_instance.id}"
        }
        
        stage('delete instance') {
            echo "Deleting the instance"

            status = query_instance.delete()
        }

        stage('get image by name') {
            echo "Retrieve the image data by name"

            query_image = Image.queryByName("${GCP_INSTANCE_NAME}-image", this)
            echo "image_name: ${query_image.name}, image id: ${query_image.id}"
        }
        
        stage('delete image') {
            echo "Deleting the image file"

            status = query_image.delete()
        }

    }

    if (!persist) {
        cleanWs()
        deleteDir()
    }
}
