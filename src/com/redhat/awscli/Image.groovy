#!/usr/bin/env groovy
package com.redhat.awscli;

class Image {

    def pipeline

    String Architecture
    String CreationDate
    String ImageId
    String ImageLocation
    String ImageType
    boolean Public
    String OwnerId
    String State
    String BlockDeviceMappings
    String Description
    boolean EnaSupport
    String Hypervisor
    String Name
    String RootDeviceName
    String RootDeviceType
    String SriovNetSupport
    String VirtualizationType
    
    public static Image[] queryByName(String pattern, pipeline) {
        def query = "aws ec2 describe-images --filter Name=name,Values=\"${pattern}\""
        pipeline.echo "Query: ${query}"
        def imageJson = pipeline.sh(
            returnStdout: true,
            script: query
        )
     
        def imagesObject = pipeline.readJSON text: imageJson

        Image[] imageList = []
        imagesObject.Images.each{
            Image image = new Image(it)
            image.pipeline = pipeline
            imageList += image
        }
        Image[] sortedList = imageList.sort{ a, b ->
            return (a.CreationDate < b.CreationDate ? a : b)
        }
        return sortedList
    }
}
