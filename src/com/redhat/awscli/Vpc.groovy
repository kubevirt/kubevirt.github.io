#!/usr/env/bin groovy
package com.redhat.awscli;

// ===========================================================================
//
// Model operations on an AWS VPC Object
//
// This is a VERY NAIVE interpretation
// ===========================================================================

class Vpc {

    // Properties and Attributes
    def pipeline
    String VpcId
    String InstanceTenancy
    def Tags
    def CidrBlockAssociationSet
    def Ipv6CidrBlockAssociationSet
    String State
    String DhcpOptionsId
    String CidrBlock
    boolean IsDefault

    // Queries

    static def queryById(String vpc_id, pipeline) {
        def vpcJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-vpcs --vpc-id ${vpc_id}")
        def vpcObjects = pipeline.readJSON text: vpcJson

        def vpcs = []
        vpcObjects.Vpcs.each{
            Vpc vpc = new Vpc(it)
            vpc.pipeline = pipeline
            vpcs << vpc
        }
        // TODO: check for empty or more than 1
        return vpcs[0]
    }
    
    static def queryByName(String name, pipeline) {
        def vpcJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-vpcs --filters Name=tag:Name,Values='${name}'")
        def vpcObjects = pipeline.readJSON text: vpcJson

        def vpcs = []
        vpcObjects.Vpcs.each{
            Vpc vpc = new Vpc(it)
            vpc.pipeline = pipeline
            vpcs << vpc
        }
        return vpcs
    }

    static def create(String cidrBlock, pipeline) {
        def vpcJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 create-vpc --cidr-block ${cidrBlock}"
        )
        def vpcObject = pipeline.readJSON text: vpcJson
        Vpc vpc = new Vpc(vpcObject.Vpc)
        vpc.pipeline = pipeline
        return vpc
    }

    // this needs to test for success and flag
    def delete() {
        this.pipeline.sh(
            script: "aws ec2 delete-vpc --vpc-id ${this.VpcId}"
        )
    }

    def setName(String name) {
        this.pipeline.sh(
            script: "aws ec2 create-tags --resources ${this.VpcId} --tags Key=Name,Value=\"${name}\""
        )
        // find the tag with Key="Name"
        // Update the value
        // this.Tags[]
    }

    def enableDnsNames() {
        this.pipeline.sh(
            script: "aws ec2 modify-vpc-attribute --vpc-id ${this.VpcId} --enable-dns-hostnames"
        )
    }
}

// allow contents access to Jenkins Pipeline steps
// per http://www.aimtheory.com/jenkins/pipeline/continuous-delivery/2017/12/02/jenkins-pipeline-global-shared-library-best-practices.html
