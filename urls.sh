#!/usr/bin/env bash

set -eou pipefail

declare minikube_ip
declare -A ports
declare -a service_names=(frontend  adminer)

minikube_ip=$(minikube ip)

for service_name in "${service_names[@]}"; do
  ports[$service_name]=$(kubectl get svc "$service_name" -o jsonpath='{.spec.ports[*].nodePort}')
  echo -e "\e[32m$service_name \t http://${minikube_ip}:${ports[$service_name]}/\e[0m"
done






#alternatives(slow):
#minikube service frontend --url
#minikube service adminer --url
#minikube service frontend --url | xargs -I {} echo -e "\e[32mfrontend \t {}\e[0m"
#minikube service adminer --url | xargs -I {} echo -e "\e[32madminer \t {}\e[0m"
#minikube service list | grep frontend | awk '{print $8}' | xargs -I {} echo -e "\e[32mfrontend \t {}\e[0m"
#minikube service list | grep adminer | awk '{print $8}' | xargs -I {} echo -e "\e[32madminer \t {}\e[0m"