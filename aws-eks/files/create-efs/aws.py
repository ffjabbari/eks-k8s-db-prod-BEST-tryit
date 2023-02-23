import boto3
import ipaddress
import sys
import os
import time

MAX_FAILURES = 20
RETRY_INTERVAL_SEC = 1
# https://github.com/diux-dev/cluster/blob/master/create_resources.py

aws_region = os.environ.get('region_code')
print("aws_region: ", aws_region)
ec2 = boto3.resource('ec2', region_name=aws_region)

file_system_id = os.environ.get('file_system_id')
security_group_id = os.environ.get('security_group_id')
vpc_id = os.environ.get('vpc_id')
print("file_system_id: ", file_system_id)
print("security_group_id: ", security_group_id)
print("vpc_id: ", vpc_id)

list_of_ips = sys.argv[1:]
print("List of Nodes ips: ", list_of_ips)


# %%
def create_dict_of_subnets():
    subnets = ec2.subnets.filter(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    subnets_dict = {}
    for subnet in subnets:
        subnets_dict[subnet.id] = subnet.cidr_block
    return subnets_dict


# %%
def ip_belong_to_subnet(dict_of_subnets, ip):
    for subnet in dict_of_subnets:
        cidr = str(ipaddress.ip_network(dict_of_subnets[subnet])).split('/')[1]
        ip_interface = ipaddress.ip_interface(f"{ip}/{cidr}")
        if ip_interface.network == ipaddress.ip_network(dict_of_subnets[subnet]):
            return subnet
    return "None"


# %%
# os.system(f"aws efs create-mount-target --file-system-id {file_system_id} --subnet-id {subnet} --security-groups {security_group_id}")

def create_mount_target(subnet):
    print("Creating mount target for: ", subnet)
    efs_client = boto3.client('efs', region_name=aws_region)
    response = efs_client.create_mount_target(
        FileSystemId=file_system_id,
        SubnetId=subnet,
        SecurityGroups=[security_group_id]
    )
    return response


def is_good_response(response):
    code = response["ResponseMetadata"]['HTTPStatusCode']
    return 200 <= code < 300


def create_resources():
    dict_of_subnets = create_dict_of_subnets()
    print("Dict of subnets: ", dict_of_subnets)
    set_of_subnets = set()
    for ip in list_of_ips:
        set_of_subnets.add(ip_belong_to_subnet(dict_of_subnets, ip))
    print("Set of subnets: ", set_of_subnets)
    # Takes a couple of seconds for EFS to come online, with errors like this:
    # botocore.errorfactory.IncorrectFileSystemLifeCycleState: An error occurred(IncorrectFileSystemLifeCycleState) when
    # calling the CreateMountTarget operation: None
    for subnet in set_of_subnets:
        if subnet != "None":
            for retry_attempt in range(MAX_FAILURES):
                try:
                    response = create_mount_target(subnet)
                    if is_good_response(response):
                        print("success")
                        break
                except Exception as e:
                    if 'already exists' in str(e):  # ignore "already exists" errors
                        print('already exists')
                        break

                    print("Got %s, retrying in %s sec" % (str(e), RETRY_INTERVAL_SEC))
                    time.sleep(RETRY_INTERVAL_SEC)
            else:
                print("Giving up.")


if __name__ == "__main__":
    create_resources()
