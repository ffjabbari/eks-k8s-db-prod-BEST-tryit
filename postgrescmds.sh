#!/usr/bin/env bash

aws cloudformation create-stack \
  --region sa-east-1 \
  --stack-name my-eks-vpc-stack-demo \
  --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml


export AWS_REGION=sa-east-1

# list all cluster in eks output jq
aws eks list-clusters

#file_system_id=$(aws efs create-file-system \
#    --region sa-east-1 \
#    --performance-mode generalPurpose \
#    --tags Key=Name,Value=efs_for_cluster_multinetwork \
#    --query 'FileSystemId' \
#    --output text)

# list all mount point of fs-0151c9f2b7f6ae8ad in json
aws efs describe-mount-targets --file-system-id fs-0151c9f2b7f6ae8ad
# list all acces point of fs-0151c9f2b7f6ae8ad in json
aws efs describe-access-points --file-system-id fs-0151c9f2b7f6ae8ad
# who is connected to fs-0151c9f2b7f6ae8ad
aws efs describe-mount-target-security-groups --file-system-id fs-0151c9f2b7f6ae8ad



