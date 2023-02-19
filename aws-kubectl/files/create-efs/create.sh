#!/usr/bin/env bash

set -euo pipefail

function green_echo {
    echo -e "\e[32m$1\e[0m"
}

green_echo "Creating the python virtual environment"
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt

# ********************************** AMAZON EFS CSI DRIVER *************************************************************
# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html ********************************************************
green_echo "Creating the Amazon EFS CSI driver"
cluster_name=eks-cluster-multinetwork
region_code=sa-east-1

#************************* Create an IAM policy and role IT MUST BE DELETED MANUALLY manual delete
green_echo "Creating the IAM policy and role"
arn_policy=$(aws iam create-policy \
    --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
    --policy-document file://efs_csi_driver-policy.json \
    --query "Policy.Arn" \
    --output text)

green_echo "Associate the IAM OIDC provider"
eksctl utils associate-iam-oidc-provider \
    --region $region_code \
    --cluster $cluster_name \
    --approve

green_echo "Creating the IAM service account"
eksctl create iamserviceaccount \
    --cluster $cluster_name \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn  $arn_policy \
    --approve \
    --region $region_code

#************************* Install the Amazon EFS driver ********************************
green_echo "Installing the Amazon EFS driver"
# add the helm repo
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
# update the repo
helm repo update
# install a release of the driver using the Helm chart. Replace the repository address with the cluster's
# container image address: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.sa-east-1.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa

#************************* Create an Amazon EFS file system ********************************
green_echo "Creating the Amazon EFS file system"
vpc_id=$(aws eks describe-cluster \
    --name $cluster_name \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --output text)

cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region_code)

green_echo "Creating the security group"
security_group_id=$(aws ec2 create-security-group \
    --group-name MyEfsSecurityGroup \
    --description "My EFS security group" \
    --vpc-id $vpc_id \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --cidr $cidr_range

green_echo "Creating the Amazon EFS file system"
file_system_id=$(aws efs create-file-system \
    --region $region_code \
    --performance-mode generalPurpose \
    --tags Key=Name,Value=efs_for_cluster_multinetwork \
    --query 'FileSystemId' \
    --output text)

export file_system_id
export security_group_id
export vpc_id
export region_code

nodes_internal_ips=$(kubectl get nodes -o json | jq -r '.items[] | [.status.addresses[] | select(.type == "InternalIP") | .address] | join("=")')
green_echo "Creating the mount targets"
python3 aws.py $nodes_internal_ips

green_echo "Replacing the file_system_id in k8s-efs/pv.yaml"
dir_name=$(dirname "$0")
cd "$dir_name"
cd ..
dir_of_file="$(pwd)/k8s-efs/pv.yaml"
sed -i "s/volumeHandle: fs-.*/volumeHandle: $file_system_id/" "$dir_of_file"
