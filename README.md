# azure-habitat-example
Example application for blog post on deploying to AKS &amp; ACR with Habitat

See http://habitat.sh/blog/2018/05/aks-and-acr-walkthrough for the full details of the walkthrough.

## Contents
  * [scripts/setup-acr-aks.sh](scripts/setup-acr-aks.sh) - quickstart script to create a AKS cluster and ACR registry, ready to push packages to.
  * [wordpress](wordpress) - example wordpress packaged by Habitat
  * [mysql](mysql) - example mysql packaged by Habitat
  * [habitat-operator.yml](habitat-operator.yml) - Kubernetes Deployment description for the [Habitat Operator](https://github.com/habitat-sh/habitat-operator)
  * [deploy-wordpress.yml](deploy-wordpress.yml) - Kubernetes Habitat Operator description for the application 

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
