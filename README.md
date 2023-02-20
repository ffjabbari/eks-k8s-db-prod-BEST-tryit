### Using Docker compose
The images are build in the host machine using a local `Dockerfile` in each service
trough a docker compose file orchestrator. `docker-compose.yml`

The endpoints are exposed through the host machine in localhost:
- frontend: http://localhost:3000
- adminer:  http://localhost:8080

### Development
For development purposes, a compose file `compose-only-db.yml` is used to start only
the database and the adminer service. 

Once the `db` has started the services `auth-api`, `frontend`, `tasks-api`
and `users-api` will start in the host machine using `npm run dev` in each service.
## KUBERNETES
### Local Deploy
The `k8s` folder contains the kubernetes manifests to deploy the services in a local
kubernetes cluster. The `k8s/pvc` folder contains the manifests to create the persistent
volumes and persistent volume claims using a hostPath volume.

If is necessary to update the container image name for the services, for example
a new version of the image is pushed to docker hub, the name can be changed in
one of the following files
- auth-api.deployment.yaml
- frontend.deployment.yaml
- tasks-api.deployment.yaml
- users-api.deployment.yaml




#### Deploy k8s
```bash
# IMPORTANT!! first services due to env vars
kubectl apply -f k8s/services.yaml && kubectl apply -Rf k8s/
```
#### Urls
If `minikube` is used for the local cluster, the services will be exposed in the host machine.
Use this script to get the urls of the services.
```bash
bash urls.sh
```

#### Delete resources
```bash
kubectl delete -Rf k8s/ 
```
### Push script
The `push.sh` script will build the images and push them to the docker hub in a name
like `jym272/multinetwork-auth-api:latest`, make sure to configure docker hub credentials
in the host machine and the repo names must be created in docker hub, change the 
`docker_hub_repo_prefix_name` variable in the script.

```bash
# push script: change this variable to your docker hub repo prefix name
declare docker_hub_repo_prefix_name="myuser/multinetwork"
```
```bash
# Usage, it will build the images using docker-compose.yml and push them to 
# docker hub

# All services
# it uses the tag:latest and the images is built with cache by default
bash push.sh 
# it uses a custom tag
bash push.sh --tag v1.0.0
# it uses the tag:latest and build the images without cache, force rebuild
bash push.sh --no-cache
# it uses a custom tag and build the images without cache, force rebuild
bash push.sh --tag v2.0.0 --no-cache

# Selected services
# only frontend and auth-api
bash push.sh frontend auth-api
# only tasks-api with tag
bash push.sh --tag v1.0.0 tasks-api
# only users-api without cache
bash push.sh --no-cache users-api
```


### Cloud Deploy using AWS EKS
Read the README.md in `aws-kubectl` folder.


**### Local Deploy with Skaffold**