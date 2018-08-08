### Deploy a Container-based Application to OpenShift

The purpose of this section is to deploy an example application on top of OpenShift and demonstrate how containers and virtual machines can be orchestrated side by side within a single OpenShift cluster. We are going to use the existing project `myproject`.

#### Move to Project and Add Template

```
oc project myproject
oc create -f https://raw.githubusercontent.com/scollier/demo/training/manifests/app-template.yaml
```

#### Deploy Application

The command below will deploy the application [ARA Records Ansible](https://github.com/openstack/ara) or ARA for short.
According to the project's README: "ARA Records Ansible playbook runs and makes the recorded data available and intuitive for users and systems."  It is a simple web-based python application that is easily deployed to OpenShift. 

```
oc new-app --template ara
```
The following objects will be created:

- [BuildConfig](https://docs.openshift.org/latest/dev_guide/builds/build_strategies.html#docker-strategy-options) 
- [ImageStream](https://docs.openshift.org/latest/dev_guide/managing_images.html) 
- [DeploymentConfig](https://docs.openshift.org/latest/dev_guide/deployments/how_deployments_work.html)
- [Route](https://docs.openshift.org/latest/dev_guide/routes.html)
- [Service](https://docs.openshift.org/latest/architecture/core_concepts/pods_and_services.html#services)


#### Review Objects


Let's show our `BuildConfig` and watch the container build log. The ara `BuildConfig` creates a new container image from the Dockerfile provided in our GitHub repository. While this is running, feel free to explore the links above to learn more about these OpenShift objects.

```
oc get bc
oc logs -f bc/ara
```

Once that is complete we can confirm that our `DeploymentConfig` has rolled out. The `ara` `DeploymentConfig` 
describes the desired state of the application. 

```
oc get dc
oc rollout status dc/ara
```

Now let's take a look at the `Service` and `Route`. A `Route` exposes a `Service` to allow ingress traffic access via a hostname.
In the case of ARA this allows us to view the web interface of the application.
A `Service` provides a consistent load balanced endpoint that permits pods to access each other. 


```
oc get svc
oc describe svc ara
oc get route
oc describe route ara
```

This concludes this section of the lab.

[Next Lab](../lab5/lab5.md)\
[Previous Lab](../lab3/lab3.md)\
[Home](../../README.md)
