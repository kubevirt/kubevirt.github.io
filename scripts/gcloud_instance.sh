#!/bin/sh

function find_current_version() {
    # Save the image versions in an array
    declare -a local versions
    versions=($(gsutil ls gs://kubevirt-button/ |  sed -e 's|gs://kubevirt-button/||' -e 's/.tar.gz//' | sort -r -n -t. -k2))

    echo ${versions[0]}
}

function create_image() {
    local image_name=$1
    local file_url=$2
    
    echo "Creating an image from: ${file_url}"
    gcloud compute images create --format json ${image_name} \
           --source-uri ${file_url} \
           --description "Demo test image for kubevirt" \
           --family centos
}

function delete_image() {
    local image_name=$1
    
    echo "Deleting an image"

    gcloud compute images delete --quiet ${image_name}
}

function create_instance() {
    local instance_name=$1
    local image_name=$2
    local zone=$3
    local username=$4
    local public_key=$5

    local md_value="${username}:ssh-rsa ${public_key} ${username}"
    
    echo "Creating an instance: ${instance_name} from ${image_name}"
    gcloud compute instances create --format json ${instance_name} \
           --image ${image_name} \
           --zone ${zone} \
           --custom-cpu 2 \
           --custom-memory 8GB \
           --metadata ssh-keys="${md_value}"
                        
           
}

function delete_instance() {
    local instance_name=$1
    local zone=$2
    echo "Deleting instance: ${instance_name}"
    gcloud compute instances delete --quiet --zone ${zone} ${instance_name}
}

function instance_add_public_key() {
    local instance_name=$1
    local zone=$2
    local username=$3
    local public_key=$4

    local md_value="${username}:ssh-rsa ${public_key} ${username}"
    
    echo "Adding SSH public key to instance ${instance_name}"
    
    gcloud compute instances add-metadata ${instance_name} --zone ${zone} \
           --metadata ssh-keys="${md_value}"

}

function get_instance_fqdn() {
    local instance_name=$1
    local zone=$2

    local ipv4_address=$(
        gcloud --format json compute instances describe --zone ${zone} kubevirt-demo-test | jq --raw-output '.networkInterfaces[].accessConfigs[] | select( .name == "external-nat") | .natIP')

    host ${ipv4_address} | awk '{print $5}'
}

function get_instance_status() {
    local instance_name=$1
    local zone=$2

    gcloud --format json compute instances describe \
           --zone ${zone} \
           ${instance_name} |
        jq --raw-output '.status'
}

# ============================================================================
#
# MAIN
#
# ============================================================================
zone=us-central1-b
image_name="kubevirt-demo-test-image"
instance_name="kubevirt-demo-test"
username="centos"

public_key="AAAAB3NzaC1yc2EAAAADAQABAAABAQDGO49laHl6FvJbWSz77EOc19lSbhIUr2asidzKqQV9lkAVdNFPjroH8JaoQK8I1Q0D0txgjYV6cD7tBE8lW0ggAASPpammyVkE+Cr+C/bP8cMDPj/wSZ+mEA0xCjJfeUSabodTnU9lVOScycfT7GDAVzda2qwVS+ZMhQCss94wJp0PbrPIrK/5SC9hayImctLfp3qMTuOlVV5bFD3te0Lz3HVo5oJePYIKxOBL4h783AidbBTeUPpQXkI/fWhh7NOC2KKZtZ2Gs39DdWNtJ3byLHH2mt6ReNpdHjunUDdouPiXjSi4QJC+pN9xC6hFLprifsqgbjW+KudOFtVDa6hF"


echo "Finding image file"
kubevirt_version=$(find_current_version)
GS_URL=gs://kubevirt-button/${kubevirt_version}.tar.gz
echo "GS_URL = ${GS_URL}"

create_image ${image_name} ${GS_URL}

create_instance ${instance_name} ${image_name} ${zone} \
                ${username} "${public_key}"


fqdn=$(get_instance_fqdn ${instance_name} ${zone})

echo "FQDN: ${fqdn}"

poll_rate=10
max_tries=30
tries=0
status=UNKNOWN

while [ ${status} != 'RUNNING' -a ${tries} -le ${max_tries} ] ; do
    status=$(get_instance_status ${instance_name} ${zone})
    if [ ${status} != 'RUNNING' ] ; then
        tries=$(($tries + 1))
        echo "try: ${tries} sleeping for ${poll_rate} seconds"
        sleep ${poll_rate}
    fi
done

tries=0
success=false

ssh-keygen -R ${fqdn}

while [ ${success} = 'false' -a ${tries} -le ${max_tries} ] ; do
    ssh -i ~/.ssh/gcp-kubevirt-demos \
        -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        ${username}@${fqdn} uptime

    [ $? -eq 0 ] && success=true
    tries=$(($tries + 1))
    echo "try: ${tries} sleeping for ${poll_rate} seconds"
    sleep ${poll_rate}
done

#instance_add_public_key kubevirt-demo-test us-central1-b centos "${public_key}"

delete_instance kubevirt-demo-test us-central1-b

delete_image kubevirt-demo-test-image
