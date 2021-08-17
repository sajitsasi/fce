#!/bin/bash

if [ -f ./.key ]; then
    KEY=$(cat .key)
else
    KEY=${RANDOM}
    echo -n ${KEY} > .key
fi

DIR=$(pwd)
export AZ_LOCATION="westus2"
export AZ_RG="aks-fce-${KEY}-rg"
export AZ_AKS_SUBNET="aks-subnet"
export AZ_VM_SUBNET="vm-subnet"
export AZ_PE_SUBNET="pe-subnet"
export AZ_VNET="aks-fce-vnet"
export AZ_VNET_CIDR="10.125.0.0/16"
export AZ_AKS_CLUSTER="aks-fce-${KEY}"
export AZ_AKS_SUBNET_CIDR="10.125.0.0/20"
export AZ_VM_SUBNET_CIDR="10.125.16.0/24"
export AZ_PE_SUBNET_CIDR="10.125.18.0/24"
export AZ_AKS_SVC_CIDR="10.125.17.0/24"
export AZ_AKS_DNS_IP="10.125.17.10"
export AZ_ACR_NAME="acr${KEY}"
export AZ_PE_AKS_MASTER="${AZ_AKS_CLUSTER}-pe"

export RATINGS_API_DEPLOY_YAML="ratings-api-deployment.yaml"
export RATINGS_API_SERVICE_YAML="ratings-api-service.yaml"
export RATINGS_API_HPA_YAML="ratings-api-hpa.yaml"
export RATINGS_WEB_DEPLOY_YAML="ratings-web-deployment.yaml"
export RATINGS_WEB_SERVICE_YAML="ratings-web-service.yaml"
export RATINGS_WEB_SERVICE_CLUSTERIP_YAML="ratings-web-service-clusterip.yaml"
export RATINGS_WEB_INGRESS_YAML="ratings-web-ingress.yaml"
export RATINGS_WEB_INGRESS_TLS_YAML="ratings-web-ingress-tls.yaml"
export CLUSTER_ISSUER_YAML="cluster-issuer.yaml"
export LOGREADER_RBAC_YAML="logreader-rbac.yaml"
export AKS_LAW_WORKSPACE="aks-fce-${KEY}-workspace"

GREEN="\e[01;32m"
BLUE="\e[01;36m"
RED="\e[01;31m"
NOCOL="\e[0m"
function runcmd() {
  echo -en "${BLUE}+ $@${NOCOL}">&2
  out=$($@ 2>&1)
  if [ $? -eq 0 ]; then
    echo -e "${GREEN} -- success! ${NOCOL}"
  else
    echo -e "\n${RED}${out}${NOCOL}"
    echo "exiting"
    exit -1
  fi
}

function pruncmd() {
  echo -e "${BLUE}+ $@${NOCOL}">&2
  $@ 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}command '$@' -- success! ${NOCOL}"
  else
    echo -e "\n${RED}$@ -- FAILED!!!${NOCOL}"
    echo "exiting"
    exit -1
  fi

}

function printcmd() {
  echo -e "${GREEN}$@${NOCOL}"
}
