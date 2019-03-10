#!/usr/bin/env groovy
package com.redhat.awscli;

class RouteTable {
    def pipeline

    List Associations
    List PropagatingVgws
    String RouteTableId
    List Routes
    List Tags
    String VpcId

    static def queryById(String RouteTableId, pipeline) {
        def rtJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-route-tables --route-table-id ${RouteTableId}"
        )
        def rtObjects = pipeline.readJSON text: rtJson

        def rtList = []
        rtObjects.RouteTables.each{
            RouteTable rt = new RouteTable(it)
            rt.pipeline = pipeline
            rtList << rt
        }
        return rtList
    }

    static def queryByVpcId(String VpcId, pipeline) {
        def rtJson = pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-route-tables --filter Name=vpc-id,Values=${VpcId}"
        )

        def rtObjects = pipeline.readJSON text: rtJson

        def rtList = []
        rtObjects.RouteTables.each{
            RouteTable rt = new RouteTable(it)
            rt.pipeline = pipeline
            rtList << rt
        }
        return rtList        
    }

    def refresh() {
        def rtJson = this.pipeline.sh(
            returnStdout: true,
            script: "aws ec2 describe-route-tables --route-table-id ${this.RouteTableId}"
        )

        def rtObjects = this.pipeline.readJSON text: rtJson

        // check for length != 1
        def rt = rtObjects.RouteTables[0]

        rt.each{
            key, value -> this[key] = value
        }
    }

    def createRoute(String cidrDest, String igwId) {
        this.pipeline.sh(
            script: "aws ec2 create-route --route-table-id ${this.RouteTableId} --gateway-id ${igwId} --destination-cidr-block ${cidrDest}"
        )
    }

    def deleteRoute(String cidrDest) {
        this.pipeline.sh(
            script: "aws ec2 delete-route --route-table-id ${this.RouteTableId} --destination-cidr-block ${cidrDest}"
        )
    }

    def associateSubnet(String SubnetId) {
        def respJson = this.pipeline.sh(
            script: "aws ec2 associate-route-table --route-table ${this.RouteTableId} --subnet-id ${SubnetId}"
        )
    }

    def disassociateSubnet(String SubnetId) {
        def respJson = this.pipeline.sh(
            script: "aws ec2 disassociate-route-table --association-id ${this.RouteTableAssocationId}"
        )
    }
}
