#!/usr/bin/env groovy
package com.redhat.gcloud;

class Instance {

    def pipeline

    boolean canIpForward
    String cpuPlatform
    String creationTimestamp
    boolean deletionProtection
    def disks
    String id
    String kind
    String labelFingerprint
    String machineType
    def metadata
    String name
    def networkInterfaces
    def scheduling
    String selfLink
    def serviceAccounts
    boolean startRestricted
    String status
    def tags
    String zone

    static public queryByName(String name, String zone, pipeline) {
        pipeline.echo "Getting instance ${name}"

        def query = "gcloud --format json compute instances describe --zone ${zone} ${name}"
        
        def instanceJson = pipeline.sh(
            returnStdout: true,
            script: query
        )

        def instanceObject = pipeline.readJSON text: instanceJson

        def instance = new Instance(instanceObject)
        instance.pipeline = pipeline
        
        return instance
    }

    static public create(String name, String image, String zone, String username, String public_key, pipeline) {
        pipeline.echo "Creating instance ${name}"

        def md_value="${username}:ssh-rsa ${public_key} ${username}"
        
        def instanceJson = pipeline.sh(
            returnStdout: true,
            script: "gcloud compute instances create --format json ${name} --image ${image} --zone ${zone} --custom-cpu 2 --custom-memory 8GB --metadata ssh-keys=\"${md_value}\""
        )

        def instanceObject = pipeline.readJSON text: instanceJson
        def instance = new Instance(instanceObject[0])
        instance.pipeline = pipeline
        
        return instance
    }

    def refresh() {
        this.pipeline.echo "refreshing image"
        def iJson = this.pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-instances --instance-id ${this.InstanceId}"
        )

        def iObject = this.pipeline.readJSON text: iJson

        // check for length != 1
        def instance = iObject
        instance.each{
            key, value -> this[key] = value
        }
    }

    def delete() {
        this.pipeline.echo "deleting image"
        this.pipeline.sh(
            "gcloud compute instances delete --zone ${this.zone} ${this.name}"
        )
    }

    def getStatus() {
        this.pipeline.echo "getting status of image"
    }

    def sshStatus(String command) {
        int statusCode = this.pipeline.sh(
                returnStatus: true,
                script: "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 centos@${this.publicIpAddress} ${command}"
            )
        return statusCode
    }

    String getPublicIpAddress() {
        return this.networkInterfaces[0].accessConfigs[0].natIP

    }
}
