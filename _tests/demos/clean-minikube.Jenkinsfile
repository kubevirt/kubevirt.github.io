


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
                    name: 'DEBUG',
                    description: 'ask commands to print details',
                    $class: 'hudson.model.BooleanParameterDefinition',
                    defaultValue: false
                ]
           ]
        ]
    ]
)

debug = DEBUG.toBoolean()

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

def clean_minikube() {
    echo "cleaning minikube"
    sh "${WORKSPACE}/bin/minikube delete"

    // check if the VM is still present

    try {
        // stop the VM
        sh "virsh --connect qemu:///system destroy minikube"

        // delete the VM
        sh "virsh --connect qemu:///system undefine minikube"
    } catch (err) {
        echo "error removing VMs: ${err}"
    }
}

def check_virt_kvm() {
    echo "check_virt_kvm"
    sh("sudo systemctl status libvirtd")
}

node(TARGET_NODE) {
    if (get_running_vms().contains('minikube') == false) {
        echo "minikube VM does not exist"
    } else {
        withEnv(
            [
                "PATH=${WORKSPACE}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                "HOME=${WORKSPACE}",
                "MINIKUBE_HOME=${WORKSPACE}"
            ]
        ) {
            try {
                clean_minikube()
            } catch (err) {
                echo "error cleaning minikube"
            }
        }
        cleanWs()
        deleteDir()
    }
}
