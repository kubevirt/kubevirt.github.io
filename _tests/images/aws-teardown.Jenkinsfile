#!/usr/bin/env groovy

@Library('awscli')
import com.redhat.awscli.*;

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
                    defaultValue: 'awscli'
                ],
                [
                    name: 'AWS_CREDENTIALS',
                    $class: 'hudson.model.StringParameterDefinition',
                    description: 'AWS access credentials',
                    defaultValue: 'kubevirt-demos'
                ],
                [
                    name: 'AWS_REGION',
                    $class: 'hudson.model.StringParameterDefinition',
                    description: 'AWS region',
                    defaultValue: 'us-east-1'
                ],
                [
                    name: 'AWS_INSTANCE_ID',
                    description: "AWS Instance ID to remove",
                    $class: 'hudson.model.StringParameterDefinition'
                ]
            ]
        ]
    ]
)


node(TARGET_NODE) {

    sh "aws configure set region ${AWS_REGION}"

    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        credentialsId: AWS_CREDENTIALS,
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
    ]]) {

        Instance instance
        Vpc vpc
        Subnet[] subnets
        SecurityGroup[] sgs
        InternetGateway[] igws
        RouteTable[] rts

        stage("retrieve instance data") {
            instance = Instance.queryById(AWS_INSTANCE_ID, this)
            vpc = Vpc.queryById(instance.VpcId, this)
            subnets = Subnet.queryByVpcId(instance.VpcId, this)
            sgs = SecurityGroup.queryByVpcId(instance.VpcId, this)
            igws = InternetGateway.queryByVpcId(instance.VpcId, this)
            rts = RouteTable.queryByVpcId(instance.VpcId, this)
        }

        stage("delete instance") {            
            instance.terminate()
            while (instance.State.Name != 'terminated') {
                sleep(10)
                instance.refresh()
            }
        }

        stage("delete network") {

            rts[0].deleteRoute("0.0.0.0/0")
            igws.each {
                it.detach(vpc.VpcId)
                it.delete()
            }
            sgs.each{
                if (it.GroupName != 'default') {
                    it.delete()
                }
            }
            subnets.each { it.delete() }
            vpc.delete()
        }
    }
}
