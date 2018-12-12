// setup up and run the simple demo on four environments
//
// centos/minishift/KVM
// centos/minishift/VirtualBox


// Stage 1: Install Virtualization

// Stage 2: Install VM

// Stage 3: Install Kubevirt

// Stage 4: Execute Demos


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
                    name: 'VIRT_DRIVER',
                    description: 'Which virtualization driver to use',
                    $class: 'hudson.model.ChoiceParameterDefinition',
                    choices: [
                        "kvm",
                        "virtualbox"
                    ].join("\n"),
                    defaultValue: 'kvm'
                ],                
                [
                    name: 'MINISHIFT_VERSION',
                    description: 'What version of minishift to use (no v prefix!)',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: '1.28.0'
                ],
                [
                    name: 'MINISHIFT_GITHUB_API_TOKEN',
                    description: 'A Github API access token',
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: ''
                ],
                [
                    name: "KUBEVIRT_VERSION",
                    description: "Version of kubevirt to install (or 'none')",
                    $class: 'hudson.model.StringParameterDefinition',
                    defaultValue: "none"
                ],
                [
                    name: 'PERSIST',
                    description: 'leave the minishift service in place',
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
        ],
        disableConcurrentBuilds()
    ]
)

persist = PERSIST.toBoolean()
debug = DEBUG.toBoolean()

def verify_github_api_access() {
    echo "verifying Github API access"
}

def get_running_vms() {
    // get the list of running machines
        // get the list of running machines
    switch (VIRT_DRIVER) {
        case 'kvm':
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

    echo "Machines = ${machines}"
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

def get_openshift_client_tools() {
    TARBALL_FILENAME=sh(
        returnStdout: true,
        script: "curl --silent --location https://github.com/openshift/origin/releases/download/v3.11.0/CHECKSUM | grep -E 'openshift-origin-client-tools-.*-linux-64bit.tar.gz' | awk '{print \$2}'"
    ).trim()

    sh("curl --silent --location --remote-name https://github.com/openshift/origin/releases/download/v3.11.0/${TARBALL_FILENAME}")
    sh("tar -xzf ${TARBALL_FILENAME}")
    TARBALL_DIRNAME=TARBALL_FILENAME.minus(".tar.gz")
    sh("cp ${TARBALL_DIRNAME}/{kubectl,oc} ${WORKSPACE}/bin")
    sh("chmod a+x ${WORKSPACE}/bin/{kubectl,oc}")
    
}

def get_kvm_driver() {
    sh("curl --silent --location https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-centos7 -o ${WORKSPACE}/bin/docker-machine-driver-kvm")
    sh("chmod +x ${WORKSPACE}/bin/docker-machine-driver-kvm")
}

def get_minishift() {
    echo "get_minishift"
    sh("curl --silent --location --remote-name https://github.com/minishift/minishift/releases/download/v${MINISHIFT_VERSION}/minishift-${MINISHIFT_VERSION}-linux-amd64.tgz")
    sh("tar -xzf minishift-${MINISHIFT_VERSION}-linux-amd64.tgz minishift-${MINISHIFT_VERSION}-linux-amd64/minishift")
    sh("mv minishift-${MINISHIFT_VERSION}-linux-amd64/minishift ${WORKSPACE}/bin")
    sh ("chmod a+x ${WORKSPACE}/bin/minishift")
}

def start_minishift() {
    echo "start_minishift"
    start_log = sh(
        returnStdout: true,
        script: "${WORKSPACE}/bin/minishift start --vm-driver ${VIRT_DRIVER}"
    )

    if (start_log =~ /OpenShift server started./) {
        // check for "OpenShift server started." in stdout
        echo "Yes! it worked!"
    } else {
        echo "--- ERROR reporting startup log ---"
        echo start_log
        echo "-----------------------------"
        error "error starting minishift"
    }

    echo "--- reporting startup log ---"
    echo start_log
    echo "-----------------------------"
}

def login_as_admin() {
    sh "oc login -u system:admin"
}

//
// Minishift Pods
//   NOTE: Groovy map literal order is preserved
system_pod_count = [
    "openshift-apiserver-": 1,
    "kube-dns-": 1,
    "kube-proxy-": 1,
    "openshift-service-cert-signer-operator-": 1,
    "service-serving-cert-signer-": 1,
    "apiservice-cabundle-injector-": 1,
    "kube-controller-manager-localhost": 1,
    "master-etcd-localhost": 1,
    "kube-scheduler-localhost": 1,
    "master-api-localhost": 1,
    "openshift-controller-manager-": 1,
    "persistent-volume-setup-": 1,
    "openshift-web-console-operator-": 1,
    "router-1-": 1,
    "docker-registry-1-": 1,
    "webconsole-": 1
]

def wait_for_system_pods() {

    pod_data = sh(
        returnStdout: true,
        script: "${WORKSPACE}/bin/kubectl get pods --all-namespaces -o json"
    )

    pod_object = readJSON text: pod_data

    echo "There are ${pod_object.size()} pods"
}

def enable_weave_cni() {
    kubectl_version = sh(
        returnStdout: true,
        script: "kubectl version | base64 | tr -d '\n'"
    )
    sh "${WORKSPACE}/bin/kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=${kubectl_version}\""

}

def install_kubevirt() {

    sh "curl --silent -L -o ${WORKSPACE}/bin/virtctl https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/virtctl-v${KUBEVIRT_VERSION}-linux-amd64"
    sh "chmod a+x ${WORKSPACE}/bin/virtctl"

    // install the kubevirt operator
    sh "oc create -f https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
    
    // enable virt emulation
    sh "oc create configmap -n kubevirt kubevirt-config --from-literal debug.useEmulation=true"

    // install the kubevirt custom resource
    sh "oc create -f https://github.com/kubevirt/kubevirt/releases/download/v${KUBEVIRT_VERSION}/kubevirt-cr.yaml"

    // wait for pods to initialize
}

def clean_minishift() {
    echo "cleaning minishift"
    sh "${WORKSPACE}/bin/minishift delete -f"
}

def check_libvirt_kvm() {
    echo "check_libvirt_kvm"
    sh("sudo systemctl status libvirtd")
}

node(TARGET_NODE) {

    currentBuild.displayName = "${currentBuild.number} - minishift-${MINISHIFT_VERSION} / ${VIRT_DRIVER}"
    //sh("echo I ran")
    //echo "I ran"

    // This might not be needed here
    // checkout scm

    //stage("verify virtualization") {
    //    check_virt_kvm()
    //}

    if (get_running_vms().contains('minishift')) {
        error("minishift VM already exists")
    }

    withEnv(
        [
            "PATH=${WORKSPACE}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
            "HOME=${WORKSPACE}",
            "MINISHIFT_HOME=${WORKSPACE}",
            "MINISHIFT_GITHUB_API_TOKEN=${MINISHIFT_GITHUB_API_TOKEN}"
        ]
    ) {
        try {
            stage("prepare for mini env") {
                sh "mkdir -p bin"
                get_openshift_client_tools()
            }

            stage("install virt driver") {
                switch(VIRT_DRIVER) {
                    case 'kvm':
                        get_kvm_driver()
                        break;
                    
                    case 'virtualbox':
                        echo "no external driver for virtualbox"
                        break

                    default:
                        echo "ERROR - invalid virtualzation driver: ${VIRT_DRIVER}"
                        break;       
                }
            }

            stage("install minishift") {
                get_minishift()
            }

            stage("start minishift") {
                start_minishift()
            }

            stage("login admin user") {
                login_as_admin()
            }
            
            stage("wait_for_system_pods") {
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
                    clean_minishift()
                } catch (err) {
                    echo "error cleaning minishift"
                }
                cleanWs()
                deleteDir()
            }
        }
    }
}

