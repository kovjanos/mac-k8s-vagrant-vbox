#!/bin/sh

. /vagrant/ubuntu/k8s/config

echo "Deploying Nginx Ingress Controller ${KUBE_NGINX_BAREMETAL_INGRESS_CONTROLLER_VERSION}"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${KUBE_NGINX_BAREMETAL_INGRESS_CONTROLLER_VERSION}/deploy/static/provider/baremetal/deploy.yaml

echo "Patching Nginx Ingress Controller for static NodePort values [80:30001,443:30002]"

kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"ports":[{"port":80,"nodePort":30001}]}}'
kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"ports":[{"port":443,"nodePort":30002}]}}'

