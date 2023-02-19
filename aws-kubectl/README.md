### Utility container: kubectl

The [alpine/k8s](https://hub.docker.com/r/alpine/k8s) image is used for deploying kubernetes 
resources, is based on the alpine image, 
includes the `kubectl`, `eksctl` binary and is designed to be used as a utility container for 
**AWS EKS**. 

For ease of use, the container is configured to use the AWS credentials of the host machine, a 
_named volume_ is used to store `kubectl` config once the cluster has been deployed.
```bash
cd aws-kubectl/
# init the container on interactive mode
docker compose run --rm kubectl
#inside the container
cd files/
```
In `docker-compose.yml` a bind mount is used to copy the kubernetes files to the container, 
note that an anonymous volume is also used to prevent copying the dir __k8s/pvc__, this config 
is used to persist the postgres database, but is a **hostPath** volume and is only valid for the
host machine in a configuration with one node like **minikube**.

The volume used in the AWS EKS cluster is an **EFS-CSI** [volume](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html).

### Deploying a cluster

- Some names vars like the name of the cluster is hardcoded into the scripts. Any change must 
be replicated in both scripts. Also take into account that the default region used is 
`region_code=sa-east-1`, change it 
if necessary in the script `create.sh` and `delete_efs_and_cluster.sh`.
In the same way set the default region with `aws configure`.
- In the `create.sh` script, in `helm upgrade` section the image.repository must be be
 configured according to the region find your [correct value](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html) 
and change the part `602401143452.dkr.ecr.sa-east-1.amazonaws.com`

Once the container is running in interactive mode, the cluster can be deployed using the following
command:
```bash
#inside the container in ~/files/

# first check aws credentials, this is important, all resources and the ownership of the cluster is
# determined by these credentials.
aws sts get-caller-identity
# create the cluster (it takes about 15-20 minutes)
eksctl create cluster -f cluster.yaml
```
The k8s files are configured so that postgres persists its database on a volume, for this purpose
a AWS EFS volume is used. When the cluster is deployed, all the creation and configuration of the
EFS volume is done by executing the following command:
```bash
#inside the container in ~/files/create-efs/
bash create.sh
```
The EFS volume is created with mount targets in the same VPC as the cluster, and the security 
group of the EFS volume is configured to allow access from the security group of the cluster.

The script also change the file system id of the EFS volume in the `k8s-efs/pv.yaml` file, this
is necessary because the file system id is generated randomly by AWS.
### Initializing the app

The containers can be initialized by executing the following command:
```bash
#inside the container in ~/files/

# first pv, pvc and storage class for the efs volume
kubectl apply -f k8s-efs/
cd ..

#inside the container in ~/

# IMPORTANT!! services first due to environment variables
kubectl apply -f k8s/services.yaml && kubectl apply -f k8s
```

- #### Urls
  Once the status of all containers is `Running` (`kubectl get pods`) about two minutes the first 
  time, the app can be accessed using the  following script, the links may take a while due to 
  load balancers in services.
    ```bash
    #inside the container in ~/files
    bash urls.sh
    ```

### Deleting the cluster
First, stop and delete all resources in the cluster
```bash
#inside the container in ~/
kubectl delete -f k8s && kubectl delete -f files/k8s-efs/ 
```
If an EFS volume wasn't created, the cluster can be deleted using the following command:
```bash
#inside the container in ~/files/
eksctl delete cluster -f cluster.yaml
```
Otherwise, the EFS volume must be deleted first, then the security group, then the cluster and 
finally an IAM policy that was created for the EFS volume. All these steps can be done by executing
the following command:
```bash
#inside the container in ~/files/
bash delete_efs_and_cluster.sh
```
