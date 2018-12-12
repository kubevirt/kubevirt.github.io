#!/usr/bin/env groovy
package com.redhat.awscli;

class InternetGateway {

    def pipeline

    List Attachments
    String InternetGatewayId
    List Tags

    static def queryById(String gwId, pipeline) {
        def gwJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-internet-gateways --internet-gateway-id ${gwId}"
        )

        def gwObjects = pipeline.readJSON text: gwJson
        def gateways = []
        gwObjects.InternetGateways.each{
            InternetGateway gw = new InternetGateway(it)
            gw.pipeline = pipeline
            gateways << gw
        }
        return gateways[0]
    }

    static def queryByVpcId(String vpcId, pipeline) {
        def gwJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${vpcId}"
        )

        def gwObjects = pipeline.readJSON text: gwJson
        def gateways = []
        gwObjects.InternetGateways.each{
            InternetGateway gw = new InternetGateway(it)
            gw.pipeline = pipeline
            gateways << gw
        }
        return gateways
    }

    static def create(pipeline) {
        def gwJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 create-internet-gateway"
        )

        def gwObject = pipeline.readJSON text: gwJson 
        def gateway = new InternetGateway(gwObject.InternetGateway)
        gateway.pipeline = pipeline

        return gateway
    }

    def delete() {
        this.pipeline.sh(
            script: "aws ec2 delete-internet-gateway --internet-gateway-id ${this.InternetGatewayId}"
        )
    }

    def setName(String name) {
        this.pipeline.sh(
            script: "aws ec2 create-tags --resources ${this.InternetGatewayId} --tags Key=Name,Value=\"${name}\""
        )
        
        // find the tag with Key="Name"
        // Update the value
        // this.Tags[]
    }

    def attach(String VpcId) {
        this.pipeline.sh(
            script: "aws ec2 attach-internet-gateway --internet-gateway-id ${this.InternetGatewayId} --vpc-id ${VpcId}"
        )
    }

    def detach(String VpcId) {
        this.pipeline.sh(
            script: "aws ec2 detach-internet-gateway --internet-gateway-id ${this.InternetGatewayId} --vpc-id ${VpcId}"
        )
    }
}
