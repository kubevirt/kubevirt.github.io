#!/usr/bin/env groovy
package com.redhat.awscli;

class Instance {

    def pipeline

    int AmiLaunchIndex
    String ImageId
    String InstanceId
    String InstanceType
    String KeyName
    String LaunchTime
    def Monitoring
    def Placement
    String PrivateDnsName
    String PrivateIpAddress
    def ProductCodes
    String PublicDnsName
    String PublicIpAddress
    def State
    String StateReason
    String StateTransitionReason
    String SubnetId
    String VpcId
    String Architecture
    def BlockDeviceMappings
    String ClientToken
    boolean EbsOptimized
    boolean EnaSupport
    String Hypervisor
    def NetworkInterfaces
    String RootDeviceName
    String RootDeviceType
    def SecurityGroups
    boolean SourceDestCheck
    def Tags
    String VirtualizationType
    def CpuOptions

    static public queryById(String instanceId, pipeline) {
        def instanceJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-instances --instance-id ${instanceId}"
        )

        def instanceObjects = pipeline.readJSON text: instanceJson

        def instances = []
        instanceObjects.Reservations[0].Instances.each{
            Instance instance = new Instance(it)
            instance.pipeline = pipeline
            instances << instance
        }
        return instances[0]
    }
    
    static public create(String imageId, String subnetId, String groupId, String keyName, pipeline) {

        def blockDeviceSpec = "'DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,VolumeSize=32,VolumeType=gp2}'"

        def instanceJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 run-instances --image-id ${imageId} --instance-type t2.large --instance-initiated-shutdown-behavior terminate --block-device-mappings ${blockDeviceSpec} --key-name ${keyName}  --security-group-ids ${groupId} --subnet-id ${subnetId} --tag-specifications  'ResourceType=instance,Tags=[{Key=Name,Value=${keyName}}]'"
        )

        def instanceList = pipeline.readJSON text: instanceJson
        def instance = new Instance(instanceList.Instances[0])
        instance.pipeline = pipeline
        return instance
    }


    def refresh() {
        def iJson = this.pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-instances --instance-id ${this.InstanceId}"
        )

        def iObjects = this.pipeline.readJSON text: iJson

        // check for length != 1
        def instance = iObjects.Reservations[0].Instances[0]
        instance.each{
            key, value -> this[key] = value
        }
    }

    def terminate() {
        pipeline.sh(
            "aws ec2 terminate-instances --instance-id ${this.InstanceId}"
        )
    }

    def getStatus() {
        def statusJson = this.pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-instance-status --instance-id ${this.InstanceId}"
        )

        def status = this.pipeline.readJSON text: statusJson

        return status.InstanceStatuses[0]
    }

    def sshStatus(String command) {
        int statusCode = this.pipeline.sh(
                returnStatus: true,
                script: "ssh -o StrictHostKeyChecking=no centos@${this.PublicDnsName} ${command}"
            )
        return statusCode
    }
}
