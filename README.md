## Microservices with Node.js, React, Docker, Kubernetes and AWS EKS
### Using Docker compose
The images are build in the host machine using a local `Dockerfile` in each service
trough a docker compose file orchestrator. `docker-compose.yml`
```bash
# start the services
docker compose up -d
# delete the services
docker compose down
```
The endpoints are exposed through the host machine in localhost:
- frontend: http://localhost:3000
- adminer:  http://localhost:8080

### Development in Host
For development purposes, a compose file `compose-only-db.yml` is used to start only
the database and the adminer service. 
```bash
# start the only-db service
docker compose -f compose-only-db.yml up -d
# delete the only-db service
docker compose -f compose-only-db.yml down
```

Once the `db` has started the services `auth-api`, `frontend`, `tasks-api`, `users-api` and
`frontend` will start in the host machine using `npm run dev` in each respective folder.

## KUBERNETES

There is two stages: **local** and **eks**. The `k8s` folder contains the kubernetes manifests
structured in two folders: `base` and `overlay` following the `kustomize` [structure](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#bases-and-overlays).

### Local Deploy
#### Deploy k8s
The deploy is realized using [kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/).
```bash
kubectl apply -k ./k8s/overlay/local
```
#### Urls
If `minikube` is used for the local cluster, the services will be exposed in the host machine.
Use this script to get the urls of the services.
```bash
bash urls.sh
```

#### Delete resources
```bash
kubectl delete -k ./k8s/overlay/local
```
### Push script
The `push.sh` script will build the images and push them to the docker hub in a name
like `jym272/multinetwork-auth-api:latest` -> `myuser/multinetwork-service:latest`, 
make sure to configure docker hub credentials in the host machine and the repo names must be 
created in docker hub, change the `docker_hub_repo_prefix_name` variable in the script.

```bash
# push script: change this variable to your docker hub repo prefix name
declare docker_hub_repo_prefix_name="myuser/multinetwork"
```
Also there is a `kustomization` available in the `k8s` folder to change the image name in all 
manifests according to your docker hub repo image names. Change the values of **newName**
and **newTag** in the files:
- `k8s/overlay/eks/kustomization.yaml`
- `k8s/overlay/local/kustomization.yaml`

```bash
# Usage, it will build the images using docker-compose.yml and push them to 
# docker hub

# All services will be built and pushed
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
Follow instructions of [README.md](./aws-kubectl/README.md) file in `aws-kubectl` folder.