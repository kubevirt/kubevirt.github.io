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

def gcloud_login_service_account(String project, String username, String keyfile) {
    sh "gcloud config set project ${project}"
    sh "gcloud auth activate-service-account '${username}' --key-file='${keyfile}'"
}

def gcloud_get_files(String path) {
    def file_list = sh(
        returnStdout: true,
        script: "gsutil ls gs:/${path}"
    )

    return file_list.split('\n')
}

def kubevirt_file_version(String filepath) {
    // get the version string out of a gcloud file path
    // the version string pattern is: v{\d+}.{\d+}.{\d+}

    def version_match = (filepath =~ /v(\d+\.\d+\.\d+)/)

    return version_match[0][1]
}

@NonCPS
def sort_versions(version_list) {

    Comparator cmp_version = { String v0string, String v1string ->
        def v0split_match = (v0string =~ /(\d+)\.(\d+)\.(\d+)/)
        def v1split_match = (v1string =~ /(\d+)\.(\d+)\.(\d+)/)
        
        v0split = v0split_match[0][1..3].collect { it.toInteger() }
        v1split = v1split_match[0][1..3].collect { it.toInteger() }

        def f0 = v0split[0] <=> v1split[0]
        if (f0 != 0) { return f0 }

        def f1 = v0split[1] <=> v1split[1]
        return (f1 != 0) ? f1 : v0split[2] <=> v1split[2]
    }
    
    Collections.sort(version_list, cmp_version)

    return version_list
}

node(TARGET_NODE) {

    checkout scm

    withCredentials(
        [
            file(credentialsId: GCP_KEY_FILE, variable: 'gcp_key_file'),
            string(credentialsId: GCP_INSTANCE_PUBLIC_KEY_NAME, variable: 'instance_public_key')
        ]
    ) {
        
        stage('Configure gcloud auth') {
            echo "Configuring gcloud auth"
            gcloud_login_service_account(GCP_PROJECT, GCP_SERVICE_ACCOUNT, gcp_key_file)
        }

        stage('find current version') {
            echo "finding the most recent source file for an image"
            image_files = gcloud_get_files("/kubevirt-button/")

            
            image_versions = image_files.findAll {
                it =~ /\d+\.\d+\.\d+/
            }.collect {
                kubevirt_file_version(it)
            }

            def sorted_versions = sort_versions(image_versions)

            current_version = sorted_versions[-1]
            echo "current version = ${current_version}"
        }
        
        stage('create image from file') {
            echo "Creating a runtime image from stock file"

            def gsfile = "gs://kubevirt-button/v${current_version}.tar.gz"

            test_image = Image.create("${GCP_INSTANCE_NAME}-image", gsfile, this)
            echo "image name: ${test_image.name}, image id: ${test_image.id}"
        }

        stage('get image by name') {
            echo "Trying to create an image object from an existing GCP image"

            query_image = Image.queryByName("${GCP_INSTANCE_NAME}-image", this)
            echo "image name: ${query_image.name}, image id: ${query_image.id}"
        }
        
        stage('launch instance from image') {
            echo "Launching an instance from the image file"

            test_instance = Instance.create(GCP_INSTANCE_NAME, test_image.name, GCP_ZONE, 'centos', instance_public_key, this)
        }

        stage('wait for SSH access to instance') {
            echo "Wait for SSH to new instance"

            sh "ssh-keygen -R ${test_instance.publicIpAddress}"
            
            sshagent([GCP_INSTANCE_PRIVATE_KEY_NAME]) {
                def max_tries=10
                def trynum = 0
                while(test_instance.sshStatus("uptime") != 0 && trynum < max_tries) {
                    echo "SSH try number ${trynum} of ${max_tries}"
                    sleep(30)
                    trynum += 1
                }
            }
        }

        stage("prepare for testing") {
            sshagent([GCP_INSTANCE_PRIVATE_KEY_NAME]) {
                test_instance.sshStatus("sudo yum -y install pexpect")
            }
        }
    }

    env.INSTANCE_ID=test_instance.id
    env.INSTANCE_PUBLIC_IP_ADDRESS=test_instance.publicIpAddress

    host_line = sh (
        returnStdout: true,
        script: "host ${test_instance.publicIpAddress}"
    )
    host_elements = host_line.split()
    gcp_instance_dns_name = host_elements[4]
    
    echo "GCP Instance DNS name: ${gcp_instance_dns_name} (ip address ${test_instance.publicIpAddress})"

    env.INSTANCE_PUBLIC_DNS_NAME = gcp_instance_dns_name
    
    if (!persist) {
        cleanWs()
        deleteDir()
    }
}
