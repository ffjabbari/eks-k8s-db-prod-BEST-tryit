#!/usr/bin/env bash

psql -U postgres

kubectl get svc

#delete svc db-service
kubectl delete svc db-service

users_api=$(minikube service load-balancer-multinetwork --url | head -n1)

tasks_api=$(minikube service load-balancer-multinetwork --url | tail -n1)
