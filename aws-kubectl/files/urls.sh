#!/usr/bin/env bash

set -euo pipefail

function green_echo {
    echo -e "\e[32m$1\e[0m"
}

adminer_ip=$(kubectl get svc adminer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
frontend_ip=$(kubectl get svc frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

green_echo "Adminer: http://$adminer_ip:8080"
green_echo "Frontend: http://$frontend_ip"