#!/usr/bin/env groovy

package com.redhat.gcloud;

class Image {

    def pipeline

    String archiveSizeBytes
    String creationTimestamp
    String description
    String diskSizeGb
    String family
    String id
    String kind
    String labelFingerprint
    String name
    def rawDisk
    String selfLink
    String sourceType
    String status

    static Image convertObject(imageObject, pipeline) {
        def image = new Image(imageObject)
        image.pipeline = pipeline
        
        return image
    }
    
    public static Image queryByName(String name, pipeline) {
        def query = "gcloud --format json compute images describe ${name}"

        pipeline.echo("Query: ${query}")

        def imageJson = pipeline.sh(
            returnStdout: true,
            script: query
        )
        def imageObject = pipeline.readJSON text: imageJson
        return convertObject(imageObject, pipeline)
    }

    public static Image create(String name, String gsfile, pipeline) {
        def command =  "gcloud compute images create --format json ${name} --source-uri ${gsfile} --description 'Demo test image for kubevirt' --family centos"
        
        pipeline.echo("New Image - name: ${name}, file: ${gsfile}")
        
        def imageJson = pipeline.sh (
            returnStdout: true,
            script: command
        )

        def imageObject = pipeline.readJSON text: imageJson
        // images create returns and array with a single member
        return convertObject(imageObject[0], pipeline)
    }

    def refresh() {
        this.pipeline.echo "refreshing image"

        def query = "gcloud --format json compute images describe ${name}"

        pipeline.echo("Query: ${query}")

        def imageJson = pipeline.sh(
            returnStdout: true,
            script: query
        )

        def imageObject = pipeline.readJSON text: imageJson

        imageObject.each{
            key, value -> this[key] = value
        }

    }
    
    def delete() {
        this.pipeline.echo "deleting image"

        this.pipeline.sh (
            "gcloud compute images delete ${this.name}"
        )
    }
}
