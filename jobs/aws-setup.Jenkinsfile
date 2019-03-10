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
                    name: 'OWNER_NUMBER',
                    description: "AWS Owner number",
                    $class: 'hudson.model.StringParameterDefinition'
                ],
                [
                    name: 'AWS_REGION',
                    $class: 'hudson.model.StringParameterDefinition',
                    description: 'AWS region',
                    defaultValue: 'us-east-1'
                ],
                [
                    name: 'AWS_CREDENTIALS',
                    $class: 'hudson.model.StringParameterDefinition',
                    description: 'AWS access credentials',
                    defaultValue: 'kubevirt-demos'
                ],
                [
                    name: 'INSTANCE_KEYPAIR_NAME',
                    description: "AWS SSH Keypair Name",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt-demos-ssh-name'
                ],
                [
                    name: 'INSTANCE_SSH_PRIVATE_KEY',
                    description: "Name of the SSH credentials for AWS instance",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt-demos-ssh'
                ],
                [
                    name: "INSTANCE_SSH_USERNAME",
                    description: "The username for SSH to the instance",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'centos'
                ]
            ]
        ]
    ]
)


node(TARGET_NODE) {

    checkout scm

    sh "aws configure set region ${AWS_REGION}"
    
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        credentialsId: AWS_CREDENTIALS,
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
    ]]) {
        
        stage("create network") {
            vpc = Vpc.create("192.168.2.0/24", this)
            echo "VpcId: ${vpc.VpcId}"
            vpc.setName("jenkins-test-vcp")
            vpc.enableDnsNames()

            rt = RouteTable.queryByVpcId(vpc.VpcId, this)
            echo "Route Table Id: ${rt[0].RouteTableId}"


            subnet = Subnet.create(vpc.VpcId, "192.168.2.0/24", this)
            echo "SubnetId: ${subnet.SubnetId}"
            subnet.setName("jenkins-test-sg")
            subnet.setMapPublicIpOnLaunch(true)

            sg = SecurityGroup.create("jenkins-test-sg", "Jenkins Test Security Group", vpc.VpcId, this)
            echo "GroupId: ${sg.GroupId}"
            sg.authorizeIngress('tcp', 22, "0.0.0.0/0")
            
            igw = InternetGateway.create(this)
            igw.setName("jenkins-test-igw")
            igw.attach(vpc.VpcId)

            rt[0].createRoute("0.0.0.0/0", igw.InternetGatewayId)
            rt[0].associateSubnet(subnet.SubnetId)
            rt[0].refresh()
        }

        Image[] images
        stage("select newest image") {
            images = Image.queryByName("kubevirt-centos-v*", this)

            images.each {
                echo "Image: ${it.Name}, ImageId: ${it.ImageId}"
            }
        }

        Instance instance
        stage("create instance") {
            instance = Instance.create(
                images[0].ImageId,
                subnet.SubnetId,
                sg.GroupId,
                INSTANCE_KEYPAIR_NAME,
                this
            )
            //     // wait for running
            instance.refresh()

            while (instance.State.Name != "running") {
                sleep(5)
                instance.refresh()
                echo "State: ${instance.State.Name}"
            }

            def status = instance.getStatus()
            while (status.InstanceStatus.Status != "ok" &&
                   status.SystemStatus.Status != "ok") {
                sleep(15)
                status = instance.getStatus()
            }

            // wait for SSH access
            sshagent([INSTANCE_SSH_PRIVATE_KEY]) {
                while(instance.sshStatus("uptime") != 0) {
                    sleep(30)
                }
            }
            
        }

        stage("prepare for testing") {
            sshagent([INSTANCE_SSH_PRIVATE_KEY]) {
                sh(
                    script: "ssh ${INSTANCE_SSH_USERNAME}@${instance.PublicDnsName} sudo yum -y install pexpect"
                )
            }
        }


        echo "INSTANCE_ID=${instance.InstanceId}"
        echo "INSTANCE_PUBLIC_DNS_NAME=${instance.PublicDnsName}"
        env.INSTANCE_ID=instance.InstanceId
        env.INSTANCE_PUBLIC_DNS_NAME=instance.PublicDnsName
    }
}
