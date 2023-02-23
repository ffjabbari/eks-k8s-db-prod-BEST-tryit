#!/usr/bin/env bash

set -euo pipefail

function green_echo {
    echo -e "\e[32m$1\e[0m"
}

region_code=sa-east-1
efs_name=efs_for_cluster_multinetwork
sg_name=MyEfsSecurityGroup
arn_policy_name=AmazonEKS_EFS_CSI_Driver_Policy

file_system_id=$(aws efs describe-file-systems --region $region_code --query 'FileSystems[?Name==`'$efs_name'`].FileSystemId' --output text)


function delete_efs {
  local id
  id=$(aws efs describe-file-systems --region $region_code --query 'FileSystems[?Name==`'$efs_name'`].FileSystemId' --output text)
  if [ -z "$id" ]
  then
      green_echo "The Amazon EFS instance with name: $efs_name does not exist"
  else
      aws efs delete-file-system --file-system-id "$id" --region $region_code
  fi
}
if [ -z "$file_system_id" ]
then
    green_echo "The Amazon EFS instance with name: $efs_name does not exist"
else
    green_echo "Deleting the Amazon EFS instance with name: $efs_name"
    mount_targets=$(aws efs describe-mount-targets --file-system-id "$file_system_id" --region $region_code --query 'MountTargets[*].MountTargetId' --output text)
    green_echo "Deleting mount targets: $mount_targets"
    for mount_target in $mount_targets
    do
        green_echo "Deleting mount target: $mount_target"
        aws efs delete-mount-target --mount-target-id "$mount_target" --region $region_code
    done
    MAX_FAILURES=20
    RETRY_INTERVAL_SEC=1
    failures=0
    while [ "$failures" -lt "$MAX_FAILURES" ]
    do
        if [ "$(delete_efs)" ]
        then
            echo "EFS deleted"
            break
        fi
        green_echo "Waiting for the EFS to be deleted"
        sleep $RETRY_INTERVAL_SEC
        failures=$((failures+1))
    done
    if [ "$failures" -eq "$MAX_FAILURES" ]
    then
        green_echo "The Amazon EFS instance with name: $efs_name was not deleted, try later"
        exit 1
    fi
fi

sg_id=$(aws ec2 describe-security-groups --region $region_code --query 'SecurityGroups[?GroupName==`'$sg_name'`].GroupId' --output text)
if [ -z "$sg_id" ]
then
    green_echo "The security group with name: $sg_name does not exist"
else
    green_echo "Deleting the security group with name: $sg_name"
    aws ec2 delete-security-group --group-id "$sg_id" --region $region_code
fi


green_echo "Deleting the cluster"
eksctl delete cluster -f ~/files/cluster.yaml

arn_policy=$(aws iam list-policies --region $region_code --query 'Policies[?PolicyName==`'$arn_policy_name'`].Arn' --output text)
if [ -z "$arn_policy" ]
then
    green_echo "The IAM policy with name: $arn_policy_name does not exist"
else
    green_echo "Deleting the IAM policy with name: $arn_policy_name"
    aws iam delete-policy --policy-arn "$arn_policy" --region $region_code
fi

