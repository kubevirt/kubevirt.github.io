---
layout: post
author: Filip Křepinský
description: This blog shows how KubeVirt Tekton Tasks can be utilized to automatically install and setup Windows VMs from scratch
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "Kubernetes",
    "virtual machine",
    "VM",
    "Tekton Pipelines",
    "KubeVirt Tekton Tasks",
    "Windows"
  ]
comments: true
title: Automated Windows Installation With Tekton Pipelines
pub-date: April 21
pub-year: 2021
---

# Introduction

This blog shows how we can easily automate a process of installing Windows VMs on KubeVirt with [Tekton Pipelines](https://github.com/tektoncd/pipeline).

Tekton Pipelines can be used to create a single `Pipeline` that encapsulates the installation process which can be run and replicated with `PipelineRuns`. 
The pipeline will be built with [KubeVirt Tekton Tasks](https://github.com/kubevirt/kubevirt-tekton-tasks), which includes all the necessary tasks for this example.

## Pipeline Description

The pipeline will prepare an empty Persistent Volume Claim (PVC) and download a Windows source ISO into another PVC. Both of them will be initialized with Containerized Data Importer (CDI).
It will then spin up an installation VM and use Windows Answer Files to automatically install the VM.
Then the pipeline will wait for the installation to complete and will delete the installation VM while keeping the artifact PVC with the installed operating system.
You can later use the artifact PVC as a base image and copy it for new VMs.
# Prerequisites

- KubeVirt `v0.39.0`
- Tekton Pipelines `v0.19.0`
- KubeVirt Tekton Tasks `v0.3.0`

# Running Windows Installer Pipeline 

## Obtaining a URL of Windows Source ISO

First we have to obtain a Download URL of Windows Source ISO.

1. Go to https://www.microsoft.com/en-us/software-download/windows10ISO. You can also obtain a server edition for evaluation at https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019.
2. Fill in the edition and `English` language (other languages need to be updated in windows-10-autounattend ConfigMap below) and go to the download page.
3. Right-click on the 64-bit download button and copy the download link. The link should be valid for 24 hours.  We will need this URL a bit later when running the pipeline.

## Preparing autounattend.xml ConfigMap

Now we have to prepare our autounattend.xml Answer File with the installation instructions. We will store it in a `ConfigMap`, but optionally it can be stored in a `Secret` as well. 

The configuration file can be generated with [Windows SIM](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/windows-system-image-manager-overview-topics)
or it can be specified manually according to [Answer File Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/answer-files-overview)
and [Answer File Components Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/components-b-unattend).

The following config map includes the required drivers and guest disk configuration.
It also specifies how the installation should proceed and what users should be created. 
In our case it is an `Administrator` user with `changepassword` password. 
You can also change the Answer File according to your needs by consulting the already mentioned documentation.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: windows-10-autounattend
data:
  Autounattend.xml: |
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
        <settings pass="windowsPE">
            <component name="Microsoft-Windows-PnpCustomizationsWinPE" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" processorArchitecture="amd64" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
                <DriverPaths>
                    <PathAndCredentials wcm:action="add" wcm:keyValue="1">
                        <Path>E:\viostor\w10\amd64</Path>
                    </PathAndCredentials>
                    <PathAndCredentials wcm:action="add" wcm:keyValue="2">
                        <Path>E:\NetKVM\w10\amd64</Path>
                    </PathAndCredentials>
                    <PathAndCredentials wcm:action="add" wcm:keyValue="3">
                        <Path>E:\viorng\w10\amd64</Path>
                    </PathAndCredentials>
                </DriverPaths>
            </component>
            <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SetupUILanguage>
                    <UILanguage>en-US</UILanguage>
                </SetupUILanguage>
                <InputLocale>0409:00000409</InputLocale>
                <SystemLocale>en-US</SystemLocale>
                <UILanguage>en-US</UILanguage>
                <UILanguageFallback>en-US</UILanguageFallback>
                <UserLocale>en-US</UserLocale>
            </component>
            <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DiskConfiguration>
                    <Disk wcm:action="add">
                        <CreatePartitions>
                            <CreatePartition wcm:action="add">
                                <Order>1</Order>
                                <Type>Primary</Type>
                                <Size>100</Size>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Extend>true</Extend>
                                <Order>2</Order>
                                <Type>Primary</Type>
                            </CreatePartition>
                        </CreatePartitions>
                        <ModifyPartitions>
                            <ModifyPartition wcm:action="add">
                                <Active>true</Active>
                                <Format>NTFS</Format>
                                <Label>System Reserved</Label>
                                <Order>1</Order>
                                <PartitionID>1</PartitionID>
                                <TypeID>0x27</TypeID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Active>true</Active>
                                <Format>NTFS</Format>
                                <Label>OS</Label>
                                <Letter>C</Letter>
                                <Order>2</Order>
                                <PartitionID>2</PartitionID>
                            </ModifyPartition>
                        </ModifyPartitions>
                        <DiskID>0</DiskID>
                        <WillWipeDisk>true</WillWipeDisk>
                    </Disk>
                </DiskConfiguration>
                <ImageInstall>
                    <OSImage>
                        <InstallTo>
                            <DiskID>0</DiskID>
                            <PartitionID>2</PartitionID>
                        </InstallTo>
                        <InstallToAvailablePartition>false</InstallToAvailablePartition>
                    </OSImage>
                </ImageInstall>
                <UserData>
                    <AcceptEula>true</AcceptEula>
                    <FullName>Administrator</FullName>
                    <Organization></Organization>
                    <ProductKey>
                        <Key>W269N-WFGWX-YVC9B-4J6C9-T83GX</Key>
                    </ProductKey>
                </UserData>
            </component>
        </settings>
        <settings pass="offlineServicing">
            <component name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <EnableLUA>false</EnableLUA>
            </component>
        </settings>
        <settings pass="generalize">
            <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SkipRearm>1</SkipRearm>
            </component>
        </settings>
        <settings pass="specialize">
            <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <InputLocale>0409:00000409</InputLocale>
                <SystemLocale>en-US</SystemLocale>
                <UILanguage>en-US</UILanguage>
                <UILanguageFallback>en-US</UILanguageFallback>
                <UserLocale>en-US</UserLocale>
            </component>
            <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SkipAutoActivation>true</SkipAutoActivation>
            </component>
            <component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <CEIPEnabled>0</CEIPEnabled>
            </component>
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <ComputerName>WindowsVM</ComputerName>
                <ProductKey>W269N-WFGWX-YVC9B-4J6C9-T83GX</ProductKey>
            </component>
        </settings>
        <settings pass="oobeSystem">
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <AutoLogon>
                    <Password>
                        <Value>changepassword</Value>
                        <PlainText>true</PlainText>
                    </Password>
                    <Enabled>true</Enabled>
                    <Username>Administrator</Username>
                </AutoLogon>
                <OOBE>
                    <HideEULAPage>true</HideEULAPage>
                    <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                    <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                    <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                    <NetworkLocation>Home</NetworkLocation>
                    <SkipUserOOBE>true</SkipUserOOBE>
                    <SkipMachineOOBE>true</SkipMachineOOBE>
                    <ProtectYourPC>3</ProtectYourPC>
                </OOBE>
                <UserAccounts>
                    <LocalAccounts>
                        <LocalAccount wcm:action="add">
                            <Password>
                                <Value>changepassword</Value>
                                <PlainText>true</PlainText>
                            </Password>
                            <Description></Description>
                            <DisplayName>Administrator</DisplayName>
                            <Group>Administrators</Group>
                            <Name>Administrator</Name>
                        </LocalAccount>
                    </LocalAccounts>
                </UserAccounts>
                <RegisteredOrganization></RegisteredOrganization>
                <RegisteredOwner>Administrator</RegisteredOwner>
                <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
                <FirstLogonCommands>
                    <SynchronousCommand wcm:action="add">
                        <Description>Control Panel View</Description>
                        <Order>1</Order>
                        <CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v StartupPage /t REG_DWORD /d 1 /f</CommandLine>
                        <RequiresUserInput>true</RequiresUserInput>
                    </SynchronousCommand>
                    <SynchronousCommand wcm:action="add">
                        <Order>2</Order>
                        <Description>Control Panel Icon Size</Description>
                        <RequiresUserInput>false</RequiresUserInput>
                        <CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v AllItemsIconView /t REG_DWORD /d 0 /f</CommandLine>
                    </SynchronousCommand>
                    <SynchronousCommand wcm:action="add">
                        <Order>3</Order>
                        <RequiresUserInput>false</RequiresUserInput>
                        <CommandLine>cmd /C wmic useraccount where name="Administrator" set PasswordExpires=false</CommandLine>
                        <Description>Password Never Expires</Description>
                    </SynchronousCommand>
                    <SynchronousCommand wcm:action="add">
                        <Order>4</Order>
                        <Description>Remove AutoAdminLogon</Description>
                        <RequiresUserInput>false</RequiresUserInput>
                        <CommandLine>reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 0 /f</CommandLine>
                    </SynchronousCommand>
                    <SynchronousCommand wcm:action="add">
                        <Order>5</Order>
                        <RequiresUserInput>false</RequiresUserInput>
                        <CommandLine>cmd /c shutdown /s /f /t 10</CommandLine>
                        <Description>Shuts down the system</Description>
                    </SynchronousCommand>
                </FirstLogonCommands>
                <TimeZone>Alaskan Standard Time</TimeZone>
            </component>
        </settings>
    </unattend>
---
```

## Creating the Pipeline

Let's create a pipeline which consists of the following tasks.

```
  create-source-dv --- create-vm-from-manifest --- wait-for-vmi-status --- cleanup-vm
                    |
    create-base-dv --
```

1. `create-source-dv` task downloads a Windows source ISO into a PVC called `windows-10-source-*`.
2. `create-base-dv` task creates an empty PVC for new windows installation called `windows-10-base-*`.
3. `create-vm-from-manifest` task creates a VM called `windows-installer-*`
   from the empty PVC and with the `windows-10-source-*` PVC attached as a CD-ROM.
4. `wait-for-vmi-status` task waits until the VM shuts down.
5. `cleanup-vm` deletes the installer VM and ISO PVC.
6.  The output artifact will be the `windows-10-base-*` PVC with the Windows installation.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: windows-installer
spec:
  params:
    - name: winImageDownloadURL
      type: string
    - name: autounattendConfigMapName
      default: windows-10-autounattend
      type: string
  tasks:
    - name: create-source-dv
      params:
        - name: manifest
          value: |
            apiVersion: cdi.kubevirt.io/v1beta1
            kind: DataVolume
            metadata:
              generateName: windows-10-source-
            spec:
              pvc:
                accessModes:
                  - ReadWriteOnce
                resources:
                  requests:
                    storage: 7Gi
                volumeMode: Filesystem
              source:
                http:
                  url: $(params.winImageDownloadURL)
        - name: waitForSuccess
          value: 'true'
      timeout: '2h'
      taskRef:
        kind: ClusterTask
        name: create-datavolume-from-manifest
    - name: create-base-dv
      params:
        - name: manifest
          value: |
            apiVersion: cdi.kubevirt.io/v1beta1
            kind: DataVolume
            metadata:
              generateName: windows-10-base-
            spec:
              pvc:
                accessModes:
                  - ReadWriteOnce
                resources:
                  requests:
                    storage: 20Gi
                volumeMode: Filesystem
              source:
                blank: {}
        - name: waitForSuccess
          value: 'true'
      taskRef:
        kind: ClusterTask
        name: create-datavolume-from-manifest
    - name: create-vm-from-manifest
      params:
        - name: manifest
          value: |
            apiVersion: kubevirt.io/v1alpha3
            kind: VirtualMachine
            metadata:
              generateName: windows-installer-
              annotation:
                description: Windows VM generated by windows-installer pipeline
              labels:
                app: windows-installer
            spec:
              runStrategy: RerunOnFailure
              template:
                metadata:
                  labels:
                    kubevirt.io/domain: windows-installer
                spec:
                  domain:
                    cpu:
                      sockets: 2
                      cores: 1
                      threads: 1
                    resources:
                      requests:
                        memory: 2Gi
                    devices:
                      disks:
                        - name: installcdrom
                          cdrom:
                            bus: sata
                          bootOrder: 1
                        - name: rootdisk
                          bootOrder: 2
                          disk:
                            bus: virtio
                        - name: virtiocontainerdisk
                          cdrom:
                            bus: sata
                        - name: sysprepconfig
                          cdrom:
                            bus: sata
                      interfaces:
                        - bridge: {}
                          name: default
                      inputs:
                        - type: tablet
                          bus: usb
                          name: tablet
                  networks:
                    - name: default
                      pod: {}
                  volumes:
                    - name: installcdrom
                    - name: rootdisk
                    - name: virtiocontainerdisk
                      containerDisk:
                        image: kubevirt/virtio-container-disk
                    - name: sysprepconfig
                      sysprep:
                        configMap:
                          name: $(params.autounattendConfigMapName)
        - name: ownDataVolumes
          value:
            - "installcdrom:$(tasks.create-source-dv.results.name)"
        - name: dataVolumes
          value:
            - "rootdisk:$(tasks.create-base-dv.results.name)"
      runAfter:
        - create-source-dv
        - create-base-dv
      taskRef:
        kind: ClusterTask
        name: create-vm-from-manifest
    - name: wait-for-vmi-status
      params:
        - name: vmiName
          value: "$(tasks.create-vm-from-manifest.results.name)"
        - name: successCondition
          value: "status.phase == Succeeded"
        - name: failureCondition
          value: "status.phase in (Failed, Unknown)"
      runAfter:
        - create-vm-from-manifest
      timeout: '2h'
      taskRef:
        kind: ClusterTask
        name: wait-for-vmi-status
    - name: cleanup-vm
      params:
        - name: vmName
          value: "$(tasks.create-vm-from-manifest.results.name)"
        - name: delete
          value: "true"
      runAfter:
        - wait-for-vmi-status
      taskRef:
        kind: ClusterTask
        name: cleanup-vm
```

## Running the Pipeline

To run the pipeline we need to create the following `PipelineRun` which references our `Pipeline`. 
Before we do that, we should replace DOWNLOAD_URL with the Windows source URL we obtained earlier.

The `PipelineRun` also specifies the serviceAccount names for all the steps/tasks and the timeout for the whole `Pipeline`.
The timeout should be changed appropriately; for example if you have a slow download connection.
You can also set a timeout for each task in the `Pipeline` definition.

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: windows-installer-run-
spec:
  params:
    - name: winImageDownloadURL
      value: DOWNLOAD_URL
  pipelineRef:
    name: windows-installer
  timeout: '5h'
  serviceAccountNames:
    - taskName: create-source-dv
      serviceAccountName: create-datavolume-from-manifest-task
    - taskName: create-base-dv
      serviceAccountName: create-datavolume-from-manifest-task
    - taskName: create-vm-from-manifest
      serviceAccountName: create-vm-from-manifest-task
    - taskName: wait-for-vmi-status
      serviceAccountName: wait-for-vmi-status-task
    - taskName: cleanup-vm
      serviceAccountName: cleanup-vm-task
```


## Inspecting the output


Firstly, you can inspect the progress of the windows-10-source and windows-10-base import:

```bash
kubectl get dvs | grep windows-10-

> windows-10-base-8zxwr     Succeeded          100.0%                21s
> windows-10-source-jdv64   ImportInProgress   1.01%                 20s
```

To inspect the status of the pipeline run:

```bash
kubectl get pipelinerun -l "tekton.dev/pipeline=windows-installer"

> NAME                          SUCCEEDED   REASON                          STARTTIME   COMPLETIONTIME
> windows-installer-run-n2mjf   Unknown     Running                         118s
```

To check the status of each task and its pods:

```bash
kubectl get pipelinerun -o yaml -l "tekton.dev/pipeline=windows-installer"
kubectl get pods -l "tekton.dev/pipeline=windows-installer"
```

Once the pipeline run completes, you should be left with a `windows-10-base-xxxxx` PVC (backed by a DataVolume).
You can then create a new VM with a copy of this PVC to test it.
You need to replace PVC_NAME with `windows-10-base-xxxxx` (you can use `kubectl get dvs -o name | grep -o "windows-10-base-.*"`) and PVC_NAMESPACE with the correct namespace in the following YAML.

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: windows-10-vm
spec:
  dataVolumeTemplates:
    - apiVersion: cdi.kubevirt.io/v1beta1
      kind: DataVolume
      metadata:
        name: windows-10-vm-root
      spec:
        pvc:
          accessModes:
            - ReadWriteMany
          resources:
            requests:
              storage: 20Gi
        source:
          pvc:
            name: PVC_NAME
            namespace: PVC_NAMESPACE
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: windows-10-vm
    spec:
      domain:
        cpu:
          sockets: 2
          cores: 1
          threads: 1
        resources:
          requests:
            memory: 2Gi
        devices:
          disks:
            - name: rootdisk
              bootOrder: 1
              disk:
                bus: virtio
            - name: virtiocontainerdisk
              cdrom:
                bus: sata
          interfaces:
            - bridge: {}
              name: default
          inputs:
            - type: tablet
              bus: usb
              name: tablet
      networks:
        - name: default
          pod: {}
      volumes:
        - name: rootdisk
          dataVolume:
            name: windows-10-vm-root
        - name: virtiocontainerdisk
          containerDisk:
            image: kubevirt/virtio-container-disk
```

You can start the VM and login with `Administrator` : `changepassword` credentials. Then you should be welcomed by your fresh VM.

<div class="zoom">
  <img
    src="/assets/2021-04-21-Automated-Windows-Installation-With-Tekton-Pipelines/win-started.png"
    width="100"
    height="75"
    itemprop="thumbnail"
    alt="Started Windows VM">
</div>

# Resources

- [YAML files used in this example](https://github.com/kubevirt/kubevirt-tekton-tasks/tree/main/examples/pipelines/windows-installer)
- [KubeVirt Tekton Tasks](https://github.com/kubevirt/kubevirt-tekton-tasks)
- [Tekton Pipelines](https://github.com/tektoncd/pipeline)
