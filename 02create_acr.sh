#!/bin/bash

source ./00source_vars.sh
DIR=$(pwd)

#1. Create ACR
printcmd "Creating Azure Container Registry ${AZ_ACR_NAME}"
runcmd "az acr create \
-g ${AZ_RG} \
--name ${AZ_ACR_NAME} \
--sku Standard \
--location ${AZ_LOCATION}"

#2. Build container images and push to ACR
#2a. Web image
printcmd "Build and push ratings-web image to ACR"
cd ${DIR}/src/mslearn-aks-workshop-ratings-web
az acr build \
-g ${AZ_RG} \
--registry ${AZ_ACR_NAME} \
--image ratings-web:v1 .

#2b. API image
printcmd "Build and push ratings-api image to ACR"
cd ${DIR}/src/mslearn-aks-workshop-ratings-api
az acr build \
-g ${AZ_RG} \
--registry ${AZ_ACR_NAME} \
--image ratings-api:v1 .

printcmd "Container image status in ACR"
az acr repository list -n ${AZ_ACR_NAME} -o table

#3. Configure the AKS cluster to authenticate to the ACR
printcmd "Configuring ${AZ_AKS_CLUSTER} to authenticate with ${AZ_ACR_NAME}"
runcmd "az aks update \
-g ${AZ_RG} \
-n ${AZ_AKS_CLUSTER} \
--attach-acr ${AZ_ACR_NAME}"