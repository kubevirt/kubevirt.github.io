#!/bin/bash

set -eu

IMAGE_OWNER_NUMBER=939345161466
#KEYPAIR_NAME=kubevirt-demos

declare -A DEFAULTS
DEFAULTS[INSTANCE_NAME]=kubevirt-demos
DEFAULTS[KEYPAIR_USER]=centos
DEFAULTS[KEYPAIR_NAME]=kubevirt-demos
DEFAULTS[KEYPAIR_FILE]=~/.ssh/aws-kubevirt-demos.pem

# ============================================================================
# PROCESS ARGUMENTS AND INPUTS
# ============================================================================
OPTSPEC="cdhi:I:k:nN:rvV:"

function parse_arguments() {
    while getopts "${OPTSPEC}" opt ; do
        case ${opt} in
            c) CREATE=true
               ;;
            
            d) DEBUG=true
               ;;

            h) HELP=true
               ;;

            i) INSTANCE_NAME=${OPTARG}
               ;;
            
            I) INSTANCE_ID=${OPTARG}
               ;;

            k) KEYPAIR_NAME=${OPTARG}
               ;;

            K) KEYPAIR_FILE=${OPTARG}
               ;;

            n) NOOP=true
               ;;

            N) VPC_ID=$(get_vpc_by_name ${OPTARG})
               ;;
           
            r) DELETE=true
               ;;
            
            v) VERBOSE=true
               ;;
            
            V) VPC_ID=${OPTARG}
               ;;

            U) KEYPAIR_USERNAME=${OPTARG}
               ;;
        esac
    done
}

function apply_defaults() {
    for KEY in ${!DEFAULTS[@]} ; do
        eval "$KEY=\${${KEY}:=${DEFAULTS[$KEY]}}"
    done
}

function create() {
    [ ! -z ${CREATE+x} ]
}

function delete() {
    [ ! -z ${DELETE+x} ]    
}

function debug() {
    [ ! -z ${DEBUG+x} ]
}

function noop() {
    [ -z ${NOOP+x} ]
}

# ============================================================================
# AWS NETWORK FUNCTIONS
# ============================================================================

#
# - vpc
#   - security-group
#     - allow SSH
#   - subnet     <--|
#   - route-table --|
#   - gateway --^

#
# Create the networks and other AWS parts needed to run Kubevirt image in AWS
#

# NEEDS ERROR CHECKING

# ----------------------------------------------------------------------------
# VPC Functions
# ----------------------------------------------------------------------------
function create_vpc() {
    # Create the VPC, collect the ID
    local vpc_id=$(
        aws ec2 create-vpc --cidr-block 172.16.0.0/16 |
            jq --raw-output '.Vpc.VpcId'
          )

    # Add a name tag to the new VPC
    aws ec2 create-tags \
        --resources ${vpc_id} \
        --tags Key=Name,Value="kubevirt-demos-vpc"

    # Tell the caller the ID of the new VPC
    echo ${vpc_id}
}

function delete_vpc() {
    local vpc_id=$1
    aws ec2 delete-vpc  --vpc-id ${vpc_id}
}

function get_vpc_by_name() {
    local vpc_name=$1
    aws ec2 describe-vpcs --filters Name=tag:Name,Values="${vpc_name}" --query Vpcs[0].VpcId | tr -d \"
}

function get_vpc_router_id() {
    local vpc_id=$1
    aws ec2 describe-route-tables \
        --filters Name=vpc-id,Values=${vpc_id} \
        --query RouteTables[].RouteTableId |
        jq --raw-output .[]
}

function enable_dns_names() {
    local vpc_id=$1
    aws ec2 modify-vpc-attribute --vpc-id ${vpc_id} \
        --enable-dns-hostnames 1>&2
}

# ----------------------------------------------------------------------------
# Subnet Functions
# ----------------------------------------------------------------------------
function create_subnet() {
    local vpc_id=$1
    local subnet_id=$(
        aws ec2 create-subnet --vpc-id ${vpc_id} \
            --cidr-block 172.16.1.0/24 |
            jq --raw-output '.Subnet.SubnetId')
    aws ec2 create-tags --resources ${subnet_id} \
        --tags Key=Name,Value="kubevirt-demos-subnet"
    aws ec2 modify-subnet-attribute --subnet-id ${subnet_id} \
        --map-public-ip-on-launch 1>&2
    echo ${subnet_id}
}

function create_internet_gateway() {
    local vpc_id=$1
    local gw_id=$(aws ec2 create-internet-gateway |
                      jq --raw-output '.InternetGateway.InternetGatewayId')
    aws ec2 create-tags --resources ${gw_id} \
        --tags Key=Name,Value="kubevirt-demos-gw"
    aws ec2 attach-internet-gateway --internet-gateway-id ${gw_id} \
        --vpc-id ${vpc_id}
    echo ${gw_id}
}

function add_default_route() {
    local rtb_id=$1
    local gw_id=$2
    aws ec2 create-route --route-table-id ${rtb_id} \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id ${gw_id} > /dev/null
}

function delete_default_route() {
    local rtb_id=$1
    aws ec2 delete-route --route-table-id ${rtb_id} \
        --destination-cidr-block 0.0.0.0/0
}
function link_router_to_subnet() {
    local rtb_id=$1
    local subnet_id=$2
    aws ec2 associate-route-table --route-table-id ${rtb_id} \
        --subnet-id ${subnet_id} |
        jq --raw-output '.AssociationId'
}

function create_security_group() {
    local vpc_id=$1
    local sg_id=$(aws ec2 create-security-group \
                      --description "SSH access to Kubevirt instances" \
                      --group-name "kubevirt-demos-sg" \
                      --vpc-id ${vpc_id} |
                      jq --raw-output .GroupId)
    aws ec2 authorize-security-group-ingress \
        --group-id ${sg_id} \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    echo ${sg_id}
}

function create_network() {
    local vpc_id=$(create_vpc)
    enable_dns_names ${vpc_id}
    local subnet_id=$(create_subnet ${vpc_id})
    local sg_id=$(create_security_group ${vpc_id})
    local gw_id=$(create_internet_gateway ${vpc_id})
    local rtb_id=$(get_vpc_router_id ${vpc_id})
    add_default_route ${rtb_id} ${gw_id}
    local rtassoc_id=$(link_router_to_subnet ${rtb_id} ${subnet_id})


    # NET_SPEC is global by implicit declaration
    NET_SPEC[vpc_id]=${vpc_id}
    NET_SPEC[subnet_id]=${subnet_id}
    NET_SPEC[sg_id]=${sg_id}
    NET_SPEC[gw_id]=${gw_id}
    NET_SPEC[rtb_id]=${rtb_id}
    NET_SPEC[rtassoc_id]=${rtassoc_id}

    if debug ; then
        for KEY in ${!NET_SPEC[@]} ; do
            echo ${KEY}: ${NET_SPEC[$KEY]}
        done
    fi
}

function remove_network() {
    echo "removing network"
    # unlink router from subnet

    # remove default route from router table

    # remove gateway

    # remove security group

    # remove subnet

    # remove vpc
}

# ============================================================================
# Image Functions
# ============================================================================

function get_kubevirt_centos_images() {
    local owner=$1
    local name_re=$2
    aws ec2 describe-images --owner ${owner} | \
        jq --raw-output '.Images[] | select(.Name | test("(kubevirt-centos-v.*)")) | { "id": .ImageId, "name": .Name }'    
}

function get_kubevirt_centos_image_names() {
    local owner=$1
    local name_re=$2
    aws ec2 describe-images --owner ${owner} | \
        jq --raw-output ".Images[] | select(.Name | test(\"${name_re}\")) | .Name"
}

function get_image_by_name() {
    local owner=$1
    local name=$2

    local quoted_id=$(
        aws ec2 describe-images \
            --owner ${owner} \
            --filters Name=name,Values="${name}" \
            --query Images[0].ImageId
          )
    # remove quotes
    local id=${quoted_id//\"}
    echo ${id}
}

function get_kubevirt_image_id() {
    declare -A image_names
    local image_names=$(get_kubevirt_centos_image_names $IMAGE_OWNER_NUMBER '^(kubevirt-centos-v.*)')
    #echo IMAGE_NAMES: ${image_names}

    get_image_by_name ${IMAGE_OWNER_NUMBER} ${image_names[0]}
}

# ----------------------------------------------------------------------------
# INSTANCE FUNCTIONS
# ----------------------------------------------------------------------------

function start_instance() {
    local image_id=$1
    local subnet_id=$2
    local sg_id=$3
    local key_name=$4
    
    local block_device_spec="DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true,VolumeSize=32,VolumeType=gp2}"

    aws ec2 run-instances \
        --image-id ${image_id} \
        --instance-type t2.large \
        --instance-initiated-shutdown-behavior terminate \
        --block-device-mappings "${block_device_spec}" \
        --key-name ${key_name} \
        --security-group-ids ${sg_id} \
        --subnet-id ${subnet_id} \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=kubevirt-demos}]' |
        jq --raw-output .Instances[].InstanceId
}

function instance_state() {
    local instance_id=$1
    aws ec2 describe-instances --instance-id ${instance_id} |
            jq --raw-output '.Reservations[].Instances[].State.Name'
}

function instance_status() {
    local instance_id=$1
    aws ec2 describe-instance-status --instance-id ${instance_id} |
            jq --raw-output '.InstanceStatuses[].InstanceStatus.Status'
}

function instance_system_status() {
    local instance_id=$1
    aws ec2 describe-instance-status --instance-id ${instance_id} |
            jq --raw-output '.InstanceStatuses[].SystemStatus.Status'
}

function public_dns_name() {
    local instance_id=$1
    aws ec2 describe-instances \
        --filters Name=instance-id,Values="${instance_id}"  |
        jq --raw-output '.Reservations[].Instances[].NetworkInterfaces[].Association.PublicDnsName'
}

function instance_ssh() {
    local username=$1
    local keyfile=$2
    local hostname=$3

    ssh -o StrictHostKeyChecking=no -i ${keyfile} ${username}@${hostname} uptime 2>&1 >/dev/null
}

function instance_vpc() {
    local instance_id=$1
    aws ec2 describe-instances --instance-id ${instance_id} |
        jq --raw-output  '.Reservations[].Instances[].NetworkInterfaces[].VpcId'
}

function running_instance_id_by_name() {
    local instance_name=$1
    aws ec2 describe-instances --filter Name=tag:Name,Values=kubevirt-demos |
        jq --raw-output '.Reservations[].Instances[] | select(.State.Name=="running") | .InstanceId'
}

function remove_instance() {
    local instance_id=$1
    aws ec2 terminate-instances --instance-id ${instance_id}
}


# ============================================================================
# Delete Stuff Data
# ============================================================================

function get_subnet_by_vpc() {
    local vpc_id=$1
    
    debug && echo "Getting subnet by VPC ${vpc_id}" 1>&2
    aws ec2 describe-subnets \
        --filter Name=vpc-id,Values=${vpc_id} \
        --query Subnets[0].SubnetId | tr -d \"
}

function delete_subnet() {
    local vpc_id=$1
    local subnet_id=$(get_subnet_by_vpc ${VPC_ID})
    aws ec2 delete-subnet --subnet-id=${subnet_id}
}

function remove_ingress_routing() {
    local vpc_id=$1

    local rtb_id=$(get_route_table_id_by_vpc ${vpc_id})
    local igw_id=$(get_gateway_by_vpc ${vpc_id})

    delete_default_route ${rtb_id}
    release_gateway ${igw_id} ${vpc_id}
    release_route_table ${rtb_id}
}

function get_gateway_by_vpc() {
    local vpc_id=$1
    
    debug && echo "Getting gateway by VPC ${vpc_id}" 1>&2
    aws ec2 describe-internet-gateways \
        --filter Name=attachment.vpc-id,Values=${vpc_id} \
        --query InternetGateways[0].InternetGatewayId |
        tr -d \"
}

function get_route_table_association_by_rtb() {
    local rtb_id=$1

    aws ec2 describe-route-tables \
        --filter Name=route-table-id,Values=${rtb_id} \
        --query RouteTables[].Associations[] |
        jq --raw-output '.[] | select(.SubnetId != null) | .RouteTableAssociationId'
}

function get_route_table_id_by_vpc() {
    local vpc_id=$1

    aws ec2 describe-route-tables \
        --filter Name=vpc-id,Values=${vpc_id} \
        --query RouteTables[].Associations[] |
        jq --raw-output '.[] | select(.SubnetId != null) | .RouteTableId'
}

function release_route_table() {
    local rtb_id=$1

    local rtassoc_id=$(get_route_table_association_by_rtb ${rtb_id})    
    aws ec2 disassociate-route-table --association-id ${rtassoc_id}
    # remove default route - can't delete the router table
    #aws ec2 delete-route-table --route-table-id ${rtb_id}
}

function release_gateway() {
    local igw_id=$1
    local vpc_id=$2

    aws ec2 detach-internet-gateway \
        --internet-gateway-id ${igw_id} \
        --vpc-id ${vpc_id}
    aws ec2 delete-internet-gateway --internet-gateway-id ${igw_id}
}

function get_security_group_by_vpc() {
    local vpc_id=$1

    aws ec2 describe-security-groups \
        --filter Name=vpc-id,Values=${vpc_id} |
        jq --raw-output '.SecurityGroups[] | select (.IpPermissions[].FromPort == 22) | .GroupId'
}

function release_security_group() {
    local vpc_id=$1
    local group_id=$(get_security_group_by_vpc ${vpc_id})
    aws ec2 delete-security-group --group-id ${group_id}
}

# ============================================================================
# MAIN
# ============================================================================
parse_arguments $@
apply_defaults

if create ; then
    declare -A NET_SPEC

    # Too many return values to set easily - using global array: NET_SPEC[]
    create_network

    image_id=$(get_kubevirt_image_id)

    instance_id=$(start_instance \
                      $image_id \
                      ${NET_SPEC[subnet_id]} \
                      ${NET_SPEC[sg_id]} \
                      $KEYPAIR_NAME \
               )


    echo INSTANCE_ID=${instance_id}
    
    #aws ec2 describe-instances --instance-id ${instance_id}

    debug && echo -n "WAIT FOR RUNNING " && date
    while [ $(instance_state $instance_id) != 'running' ] ; do
        sleep 5
    done
    debug && echo -n "RUNNING " && date


    debug && echo -n "WAIT FOR SYSTEM ACCESSABLE " && date
    while [ $(instance_system_status $instance_id) != 'ok' ] ; do
        sleep 5
    done
    debug && echo -n "SYSTEM ACCESSABLE " && date
        
    debug && echo -n "WAIT FOR INSTANCE ACCESSABLE " && date
    while [ $(instance_status $instance_id) != 'ok' ] ; do
        sleep 5
    done
    debug && echo -n "INSTANCE ACCESSABLE " && date

    dns_name=$(public_dns_name ${instance_id})
    echo DNS NAME: ${dns_name}

    # wait for access
    debug && echo -n "WAIT FOR SSH ACCESS " && date
    while ! instance_ssh ${KEYPAIR_USER} ${KEYPAIR_FILE} ${dns_name} ; do
        sleep 10
    done
    debug && echo -n "SSH ACCESS " && date
        
elif delete ; then

    [ -z "${INSTANCE_NAME+x}" ] ||
        INSTANCE_ID=$(running_instance_id_by_name ${INSTANCE_NAME})
    
    debug && echo "Deleting"
    [ -z "${INSTANCE_ID+x}" ] && echo  missing required INSTANCE ID && exit 2

    vpc_id=${VPC_ID:=$(instance_vpc ${INSTANCE_ID})}

    remove_instance ${INSTANCE_ID}
    debug && echo -n "WAIT FOR TERMINATED " && date
    while [ $(instance_state ${INSTANCE_ID}) != 'terminated' ] ; do
        sleep 10
    done
    debug && echo -n "TERMINATED " && date

    # if no VPC ID, exit
    [ -z "${vpc_id+x}" ] && echo missing required VPN ID && exit 2

    remove_ingress_routing ${vpc_id}
    release_security_group ${vpc_id}
    delete_subnet ${vpc_id}
    aws ec2 delete-vpc --vpc-id ${vpc_id}
fi
