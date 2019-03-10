// setup up and run the simple demo on four environments
//
// centos/minikube/KVM2
// centos/minikube/VirtualBox
// centos/minishift/KVM
// centos/minishift/VirtualBox


// Stage 1: Install Virtualization

// Stage 2: Install VM

// Stage 3: Install Kubevirt

// Stage 4: Execute Demos

// for JSON parsing
import groovy.json.JsonSlurperClassic

properties(
    [
        buildDiscarder(
            logRotator(
                artifactDaysToKeepStr: '',
                artifactNumToKeepStr: '',
                daysToKeepStr: '5',
                numToKeepStr: '10'
            )
        ),
        disableConcurrentBuilds(),
        [
            $class: 'ParametersDefinitionProperty',
            parameterDefinitions: [
                [
                    name: 'TARGET_NODE',
                    description: 'Jenkins agent node',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: 'kubevirt'
                ],
                [
                    name: 'GITHUB_OWNER',
                    description: 'Github ownerfor repos',
                    $class: 'hudson.model.ChoiceParameterDefinition',
                    choices: [
                        "markllama"
                    ].join("\n"),
                    defaultValue: 'markllama'
                ],
                [
                    name: 'SSH_KEY_ID',
                    description: 'SSH credential id to use',
                    $class: 'hudson.model.ChoiceParameterDefinition',
                    choices: [
                        "markllama"
                    ].join("\n"),
                    defaultValue: 'markllama'
                ],
                [
                    name: 'MINIKUBE_VERSION',
                    description: 'What version of minikube to use (no v prefix!)',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: '0.33.1'
                ],
                [
                    name: 'VIRT_DRIVER',
                    description: 'Which virtualization driver to use',
                    $class: 'hudson.model.ChoiceParameterDefinition',
                    choices: [
                        "kvm2",
                        "kvm",
                        "virtualbox"
                    ].join("\n"),
                    defaultValue: 'kvm2'
                ],                
                [
                    name: 'VIRT_DRIVER_VERSION',
                    description: 'What version of kvm driver to use (no v prefix!): defaults to MINIKUBE_VERSION',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: "default"
                ],
                [
                    name: "KUBEVIRT_VERSION",
                    description: "Version of kubevirt to install (or 'none')",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: "none"
                ],
                [
                    name: 'PERSIST',
                    description: 'leave the minikube service in place',
                    $class: 'hudson.model.BooleanParameterDefinition',
                    defaultValue: false
                ],
                [
                    name: 'DEBUG',
                    description: 'ask commands to print details',
                    $class: 'hudson.model.BooleanParameterDefinition',
                    defaultValue: false
                ]
            ]
        ]
    ]
)

persist = PERSIST.toBoolean()
debug = DEBUG.toBoolean()
if (VIRT_DRIVER_VERSION == "default") {
    VIRT_DRIVER_VERSION = MINIKUBE_VERSION
} else {
    echo "NOTICE: overriding default KVM driver version: ${VIRT_DRIVER_VERSION}"
}

//
// Minishift Pods
//   NOTE: Groovy map literal order is preserved
system_pod_count = [
    "coredns-": 2,
    "kube-proxy-": 1,
    "storage-provisioner": 1,
    "kube-apiserver-minikube": 1,
    "etcd-minikube": 1,
    "kube-scheduler-minikube": 1,
    "kube-addon-manager-minikube": 1,
    "kube-controller-manager-minikube": 1,
]

def get_running_vms() {
    // get the list of running machines
    switch (VIRT_DRIVER) {
        case 'kvm':
        case 'kvm2':
                
            machines = sh(
                returnStdout: true,
                script: "virsh --connect qemu:///system --readonly --quiet list --name"
            ).tokenize()
            break;
            
        case 'virtualbox':
            machines = sh(
                returnStdout: true,
                script: "vboxmanage list vms"
            ).readLines().collect { it.split().head() }
            break;
    }
    return machines
}

def get_kubectl() {
    KUBE_VERSION=sh(
        returnStdout: true,
        script:"curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt"
    ).trim()
    sh "curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -o ${WORKSPACE}/bin/kubectl"
    sh "chmod a+x ${WORKSPACE}/bin/kubectl"
}

def get_kvm_driver() {
    sh("curl --silent --location https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-centos7 -o ${WORKSPACE}/bin/docker-machine-driver-kvm")
    sh("chmod +x ${WORKSPACE}/bin/docker-machine-driver-kvm")
}

def get_kvm2_driver() {
    echo "get_kvm2_driver"
    sh ("curl --silent --location https://github.com/kubernetes/minikube/releases/download/v${VIRT_DRIVER_VERSION}/docker-machine-driver-kvm2 -o ${WORKSPACE}/bin/docker-machine-driver-kvm2")
    sh ("chmod a+x ${WORKSPACE}/bin/docker-machine-driver-kvm2")
}

def get_minikube() {
    echo "get_minikube"
    sh("curl --silent --location https://github.com/kubernetes/minikube/releases/download/v${MINIKUBE_VERSION}/minikube-linux-amd64 -o ${WORKSPACE}/bin/minikube")
    sh("chmod a+x ${WORKSPACE}/bin/minikube")
}

def start_minikube() {
    echo "start_minikube"

    MINIKUBE_VERBOSE = debug ? "-v 10" : "-v 1"
    try {
        start_log=sh(
            returnStdout: true,
            script: "${WORKSPACE}/bin/minikube start --vm-driver ${VIRT_DRIVER} ${MINIKUBE_VERBOSE}"
        ).trim()

        // There is a newer version of minikube available (v0.32.0)
        if (start_log =~ /There is a newer version of minikube available/) {
            // check stdout for "new version warning"
            echo "There is a new version of minikube available"
        }

        if (start_log =~ /Everything looks great. Please enjoy minikube!/) {
            // check stdout for "Everything looks great. Please enjoy minikube!"
            echo "Yes! it worked!"
        }

        echo "--- reporting startup log ---"
        echo start_log
        echo "-----------------------------"
    } catch (err) {
        echo "--- ERROR reporting startup log ---"
        // if (exist start_log) {
        //    echo start_log
        // }
        echo "-----------------------------"
        error "error starting minikube"
    }
}

//
// The kubevirt get pods JSON is an a
//
def wait_for_system_pods() {

    all_running = false
    tries = 0
    while (!all_running && tries < 30) {
        def poddataJson = sh(
            returnStdout: true,
            script: "${WORKSPACE}/bin/kubectl get pods --namespace kube-system -o json | jq '[ .items[] | { \"name\": .metadata.name, \"phase\": .status.phase }]'"
        )

        def poddata = readJSON text: poddataJson

        if (poddata.size() == 9 && poddata.every { p -> p.phase == "Running"}) {
            all_running = true
        }
        
        tries += 1
        sleep(5)
    }

}

def enable_weave_cni() {
    kubectl_version = sh(
        returnStdout: true,
        script: "kubectl version | base64 | tr -d '\n'"
    )
    sh "${WORKSPACE}/bin/kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=${kubectl_version}\""

}

def clean_minikube() {
    echo "cleaning minikube"
    sh "${WORKSPACE}/bin/minikube delete"

    // check if the VM is still present
    if (get_running_vms().contains('minikube')) {
        echo "minikube vm still exists"
        try {
            // stop the VM
            sh "virsh --connect qemu:///system destroy minikube"

            // delete the VM
            sh "virsh --connect qemu:///system undefine --remove-all-storage minikube"
        } catch (err) {
            echo "error removing VMs: ${err}"
        }
    }
}

def check_virt_kvm() {
    echo "check_virt_kvm"
    sh("sudo systemctl status libvirtd")
}

def install_kubevirt() {

    sh "curl --silent -L -o ${WORKSPACE}/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/virtctl-v${KUBEVIRT_VERSION}-linux-amd64"
    sh "chmod a+x ${WORKSPACE}/bin/virtctl"

    // install the kubevirt operator
    sh "kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
    
    // enable virt emulation
    sh "kubectl create configmap -n kubevirt kubevirt-config --from-literal debug.useEmulation=true"

    // install the kubevirt custom resource
    sh "kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/kubevirt-cr.yaml"

    // wait for pods to initialize
}

node(TARGET_NODE) {

    currentBuild.displayName = "${currentBuild.number} - minikube-${MINIKUBE_VERSION} / ${VIRT_DRIVER}"
    //sh("echo I ran")
    //echo "I ran"

    // This might not be needed here
    // checkout scm

    //stage("verify virtualization") {
    //    check_virt_kvm()
    //}
    if (get_running_vms().contains('minikube')) {
        error("minikube VM already exists")
    }

    withEnv(
        [
            "PATH=${WORKSPACE}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
            "HOME=${WORKSPACE}",
            "KUBECONFIG=${WORKSPACE}/kubeconfig",
            "MINIKUBE_HOME=${WORKSPACE}"
        ]
    ) {
        try {
            stage("prepare for mini env") {
                sh "mkdir -p bin"
                get_kubectl()
            }

            stage("install virt driver") {
                switch(VIRT_DRIVER) {
                    case 'kvm':
                        get_kvm_driver()
                        break;
                    
                    case 'kvm2':
                        get_kvm2_driver()
                        break;

                    case 'virtualbox':
                        echo "no external driver for virtualbox"
                        break

                    default:
                        echo "ERROR - invalid virtualzation driver: ${VIRT_DRIVER}"
                        break;       
                }
            }

            stage("install minikube") {
                get_minikube()
            }

            stage("start minikube") {
                start_minikube()
            }
           
            stage("wait for system pods") {
                wait_for_system_pods()
            }

            stage("enable weave CNI") {
                enable_weave_cni()
            }

            stage("install kubevirt") {
                if (KUBEVIRT_VERSION != 'none') {
                    echo "installing kubevirt: ${KUBEVIRT_VERSION}"
                    install_kubevirt()
                } else {
                    echo "kubevirt installation disabled"
                }
            }
 
        } finally {
            if (!persist) {
                try {
                    clean_minikube()
                } catch (err) {
                    echo "error cleaning minikube"
                }
                cleanWs()
                deleteDir()
            }
        }
    }
}
