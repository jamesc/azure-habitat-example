# azure-habitat-example
Example application for blog post on deploying to AKS &amp; ACR with Habitat

See http://habitat.sh/blog/2018/05/aks-and-acr-walkthrough for the full details of the walkthrough.

## Contents
  * [scripts/setup-aks-acr.sh](scripts/setup-aks-acr.sh) - quickstart script to create a AKS cluster and ACR 
registry, ready to push packages to.
  * [wordpress](wordpress) - example wordpress packaged by Habitat
  * [mysql](mysql) - example mysql packaged by Habitat
  * [habitat-operator.yml](habitat-operator.yml) - Kubernetes Deployment description for the 
[Habitat Operator](https://github.com/habitat-sh/habitat-operator)
  * [deploy-wordpress.yml](deploy-wordpress.yml) - Kubernetes Habitat Operator description for the application 

## Dependencies
You need the following tools installed on the workstation you're running these scripts from:

  * `az`
  * `kubectl`
  * `helm`
  * `svcat`

## Setting up the cluster

1. Run `scripts/setup-aks-acr.sh`.  This will create a resource group (by default `habitat-aks-demo`) containing
 both a AKS instance as well as a ACR registry.  It will grant Owner rights on the ACR register to the AKS 
Service Principal so it can pull images from ACR.

At the end of the run it will output some configuration details to be used for the Habitat Builder integration:

```
...
...
...
Configuration Details for Habitat Builder:
  Server URL : habitatregistry.azurecr.io
  Service Principal ID : 9104325b-d11a-40a9-8178-7ec858aed4bd
  Service Principal Password : **************
```

2. Run `scripts/setup-service-catalog.sh` to setup the Service Catalog.  This will take some time to run and get all the 
pods started correctly.  Wait unit `svcat get plans` returns successfully before progressing to next step.

You can check if the catalog is ready by looking at the status of the pods in the `catalog` namespace:

```
$ kubectl get pods --namespace catalog
NAME                                                  READY     STATUS    RESTARTS   AGE
catalog-catalog-apiserver-77dbbd4cc5-m55ds            1/2       Running   0          3m
catalog-catalog-controller-manager-6c7b679dc9-9rdhn   0/1       Running   4          3m
```

3. Run `scripts/setup-osba.sh` to install the Open Service Broker for Azure 

You can check if the broker is running by looking at the status of the pods in the `osba` namespace:

```
$ kubectl get pods --namespace osba
NAME                                              READY     STATUS    RESTARTS   AGE
osba-open-service-broker-azure-6b7d9f9c45-bjmfh   1/1       Running   3          7m
osba-redis-c555f5c6-zssxd                         1/1       Running   0          7m
```

4. Add OSBA managed database instance and binding

```
$ kubectl apply -f osba/mysql-instance.yml
serviceinstance.servicecatalog.k8s.io "osba-mysql" created
$ kubectl apply -f osba/mysql-binding.yml
servicebinding.servicecatalog.k8s.io "wordpress-mysql-binding" created
$ svcat get instances
     NAME      NAMESPACE        CLASS             PLAN            STATUS
+------------+-----------+-----------------+-----------------+--------------+
  osba-mysql   default     azure-mysql-5-7   general-purpose   Provisioning
$ svcat get bindings
           NAME             NAMESPACE    INSTANCE           STATUS
+-------------------------+-----------+------------+-----------------------+
  wordpress-mysql-binding   default     osba-mysql   ErrorInstanceNotReady
```

Wait until the instance and binding are provisioned.

5. Run `scripts/setup-habitat.sh` to install via the habitat operator via Helm

6. Configure habitat builder and republish packages

6. Run Wordpress on OSBA example

```
$ kubectl apply -f deploy-osba-wordpress.yml
```


## License
```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
