#!/usr/bin/env groovy

/*

  This pipeline uses contra-lib for executing ansible in a container on OpenShift: https://github.com/openshift/contra-lib
  This library is made available at a global level for Jenkins and is therefore not imported or defined here.

*/

  // Define the credentials to be used by pulling the relevant values from the environment
def gcp_credentials = [
  sshUserPrivateKey(credentialsId: 'kubevirt-gcp-ssh-private-key', keyFileVariable: 'SSH_KEY_LOCATION'),
  file(credentialsId: 'kubevirt-gcp-credentials-file', variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
  file(credentialsId: 'kubevirt-gcp-ssh-public-key', variable: 'GCP_SSH_PUBLIC_KEY')
]

def aws_credentials = [
  string(credentialsId: 'kubevirt-aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
  string(credentialsId: 'kubevirt-aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
  string(credentialsId: 'kubevirt-aws-subnet-id', variable: 'AWS_SUBNET_ID'),
  string(credentialsId: 'kubevirt-aws-security-group-id', variable: 'AWS_SECURITY_GROUP_ID'),
  string(credentialsId: 'kubevirt-aws-security-group', variable: 'AWS_SECURITY_GROUP'),
  string(credentialsId: 'kubevirt-aws-key-name', variable: 'AWS_KEY_NAME'),
  sshUserPrivateKey(credentialsId: 'kubevirt-aws-ssh-private-key', keyFileVariable: 'SSH_KEY_LOCATION')
]

  // Define the various environments we'll be doing this for.
def cloudEnvironments = [

  'aws': [
    'envFile': 'config/environment.aws',
    'credentials': aws_credentials
  ],

  'gcp': [
    'envFile': 'config/environment.gcp',
    'credentials': gcp_credentials
  ],

//  'minikube': [
//    'envFile': 'config/environment.gcp',
//    'credentials': gcp_credentials
//  ]
]

def notifyBuild(String environment = '', String buildStatus = 'STARTED') {
  // build status of null means successful
  buildStatus =  buildStatus ?: 'SUCCESSFUL'

  // Default values
  def colorName = 'RED'
  def colorCode = '#FF0000'
  def subject = "${environment} : ${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
  def summary = "${subject} (${env.BUILD_URL})"

  // Override default values based on build status
  if (buildStatus == 'STARTED') {
    color = 'YELLOW'
    colorCode = '#FFFF00'
  } else if (buildStatus == 'SUCCESSFUL') {
    color = 'GREEN'
    colorCode = '#00FF00'
  } else {
    color = 'RED'
    colorCode = '#FF0000'
  }

  // Send notifications
  slackSend (color: colorCode, message: summary)
}

builders = [:]

  // Programmatically construct the steps used in the pipeline process and save the
  // steps to an array where each element is a different branch of the pipeline execution.
cloudEnvironments.each { environName, environValues ->

  def podName = "${environName}-${UUID.randomUUID().toString()}"

  builders[podName] = {

    def params = [:]
    def credentials = []

    def containers = ['ansible-executor': [tag: 'latest', privileged: false, command: 'uid_entrypoint cat']]


    def archives = {
      step([$class   : 'ArtifactArchiver', allowEmptyArchive: true,
           artifacts: 'ansible-*.log', fingerprint: true])
    }

    deployOpenShiftTemplate(containersWithProps: containers, openshift_namespace: 'kubevirt', podName: podName,
         docker_repo_url: '172.30.254.79:5000', jenkins_slave_image: 'jenkins-contra-slave:latest') {

      ciPipeline(buildPrefix: 'kubevirt-image-builder', decorateBuild: decoratePRBuild(), archiveArtifacts: archives, timeout: 120, sendMetrics: false) {
        try {

            // Each branch of execution should start by setting various values to their environment-specific settings.
          stage("prepare-environment-${environName}") {

            handlePipelineStep {

              echo "STARTING TESTS FOR ${environName}"

                // Clone this git repo into the container so that included scripts can be ran.
              checkout scm

                // Establish regular variable name for creds so the references below look cleaner.
              credentials = environValues['credentials']

                // Make last minute additions to executor's environment variables
              params = readProperties file: environValues['envFile']
              params['targetEnvironment'] = "${environName}"
              params['buildID'] = "${BUILD_ID}"

            }

          } // END stage(prepare env)

          // comment: We already create/destroy in lab validation step, so removing this, reduces time to validate the labs
          // stage("${environName}-validate-provision") {
          //  executeInContainer(containerName: 'ansible-executor', containerScript: "sh tests/shell/provision-and-destroy.sh", stageVars: params, credentials: credentials)
          //}

          stage("${environName}-lab1") {
            executeInContainer(containerName: 'ansible-executor', containerScript: "sh tests/shell/lab.sh lab1", stageVars: params, credentials: credentials)
          }

          stage("${environName}-lab2") {
            executeInContainer(containerName: 'ansible-executor', containerScript: "sh tests/shell/lab.sh lab2", stageVars: params, credentials: credentials)
          }

        } catch (e) {

          echo e.toString()
          throw e

        } finally {
          /* Use slackNotifier.groovy from shared library and provide current build result as parameter */
          notifyBuild("${environName}", currentBuild.result)
        }
         // END try/catch

      } // END ciPipeline

    } // END deployOpenShiftTemplate

  } // END builders definition

} // END cloudEnvironments.each

  // Instruct the built pipeline steps to be executed in parallel
parallel builders
