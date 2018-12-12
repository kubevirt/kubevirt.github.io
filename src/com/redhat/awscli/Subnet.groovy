#!/usr/bin/env groovy

package com.redhat.awscli;

class Subnet {
    def pipeline
    String AvailabilityZone
    int AvailableIpAddressCount
    String CidrBlock
    boolean DefaultForAz
    boolean MapPublicIpOnLaunch
    String State
    String SubnetId
    List Tags
    String VpcId
    boolean AssignIpv6AddressOnCreation
    List Ipv6CidrBlockAssociationSet

    static def queryById(String subnetId, pipeline) {
        def subnetJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-subnets --subnet-id ${subnetId}"
        )

        def subnetObjects = pipeline.readJSON text: subnetJson

        def subnets = []
        subnetObjects.Subnets.each{
            Subnet subnet = new Subnet(it)
            subnet.pipeline = pipeline
            subnets << subnet
        }
        return subnets[0]
    }

    static def queryByVpcId(String vpc_id, pipeline) {
        def subnetJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-subnets --filter Name=vpc-id,Values=${vpc_id}"
        )

        def subnetObjects = pipeline.readJSON text: subnetJson

        def subnets = []
        subnetObjects.Subnets.each{
            Subnet subnet = new Subnet(it)
            subnet.pipeline = pipeline
            subnets << subnet
        }
        return subnets
    }

    static def create(String vpcId, String cidrBlock, pipeline) {
        def subnetJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 create-subnet --vpc-id ${vpcId} --cidr-block ${cidrBlock}"
        )
        def subnetObject = pipeline.readJSON text: subnetJson
        Subnet subnet = new Subnet(subnetObject.Subnet)
        subnet.pipeline = pipeline
        return subnet
    }

    def delete() {
        this.pipeline.sh(
            script: "aws ec2 delete-subnet --subnet-id ${this.SubnetId}"
        )
    }

    def refresh() {
        def subnetJson = this.pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-subnetss --subnet-id ${this.SubnetId}"
        )

        def subnetObjects = this.pipeline.readJSON text: subnetJson

        // check for length != 1
        def subnet = subnetObjects.Subnets[0]

        this.AvailabilityZone = subnet.AvailabilityZone
        this.AvailableIpAddressCount = subnet.AvailableIpAddressCount
        this.CidrBlock = subnet.CidrBlock
        this.DefaultForAz = subnet.DefaultForAz
        this.MapPublicIpOnLaunch = subnet.MapPublicIpOnLaunch
        this.State = subnet.State

        this.VpcId = subnet.VpcId
        this.AssignIpv6AddressOnCreation = subnet.AssignIpv6AddressOnCreation
        this.Ipv6CidrBlockAssociationSet = subnet.Ipv6CidrBlockAssociationSet
    }


    def setName(String name) {
        this.pipeline.sh(
            script: "aws ec2 create-tags --resources ${this.SubnetId} --tags Key=Name,Value=\"${name}\""
        )
        // find the tag with Key="Name"
        // Update the value
        // this.Tags[]
    }

    def setMapPublicIpOnLaunch(boolean MapPublicIpOnLaunch) {
        def disable = ""
        if (!MapPublicIpOnLaunch) {
            disable = "no-"
        }
        this.pipeline.sh(
            script: "aws ec2 modify-subnet-attribute --subnet-id ${this.SubnetId} --${disable}map-public-ip-on-launch"

        )
    }
}
