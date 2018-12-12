#!/usr/bin/env groovy
package com.redhat.awscli;

class SecurityGroup {

    String Description
    String GroupName
    List IpPermissions
    String OwnerId
    String GroupId
    List IpPermissionsEgress
    String VpcId

    def pipeline

    static def queryById(String groupId, pipeline) {
        def sgJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-security-groups --group-id ${groupId}"
        )
        def sgObjects = pipeline.readJSON text: sgJson
        def groups = []
        sgObjects.SecurityGroups.each{
            SecurityGroup sg = new SecurityGroup(it)
            sg.pipeline = pipeline
            groups << sg
        }
        return groups[0]
    }

    static def queryByVpcId(String vpcId, pipeline) {
        def sgJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-security-groups --filter 'Name=vpc-id,Values=${vpcId}'"
        )
        def sgObjects = pipeline.readJSON text: sgJson
        def groups = []
        sgObjects.SecurityGroups.each{
            SecurityGroup sg = new SecurityGroup(it)
            sg.pipeline = pipeline
            groups << sg
        }
        return groups
    }

    static def create(String name, String description, String vpcId, pipeline) {
        def sgIdJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 create-security-group --group-name \"${name}\" --description \"${description}\" --vpc-id ${vpcId}"
        )
        def sgId = pipeline.readJSON text: sgIdJson

        def sgJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-security-groups --group-id ${sgId.GroupId}"
        )

        def sgObject = pipeline.readJSON text: sgJson
        sgObject.SecurityGroups[0]
        SecurityGroup group = new SecurityGroup(sgObject.SecurityGroups[0])
        group.pipeline = pipeline
        return group
    }

    def delete() {
        this.pipeline.sh(
            script: "aws ec2 delete-security-group --group-id ${this.GroupId}"
        )
    }

    def authorizeIngress(String Protocol, int Port, String CidrMask) {
        this.pipeline.sh(
            script: "aws ec2 authorize-security-group-ingress --group-id ${this.GroupId} --protocol ${Protocol} --port ${Port} --cidr ${CidrMask}"
        )        
    }
}
