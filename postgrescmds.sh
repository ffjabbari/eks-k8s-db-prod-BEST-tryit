#!/usr/bin/env bash

aws cloudformation create-stack \
  --region sa-east-1 \
  --stack-name my-eks-vpc-stack-demo \
  --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml


export AWS_REGION=sa-east-1

# list all cluster in eks output jq
aws eks list-clusters
# generate kubeconfig and save it to ~/.kube/config -> THIS REPLACE THE CURRENT CONFIG
aws eks update-kubeconfig --region sa-east-1 --name test-demo
# ! now kubectl is configured to use the cluster

aws eks --region sa-east-1 update-kubeconfig --name test-demo --role-arn arn:aws:iam::712136406596:role/myAmazonEKSClusterRoleDemo

