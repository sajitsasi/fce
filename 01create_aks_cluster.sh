#!/bin/bash

source ./00source_vars.sh

#1. Create Azure Resource Group
printcmd "Creating azure resource group"
runcmd "az group create --name ${AZ_RG} --location ${AZ_LOCATION}"

#2. Create VNET
printcmd "Creating VNET + AKS subnet"
runcmd "az network vnet create \
-g ${AZ_RG} \
-n ${AZ_VNET} \
--address-prefixes ${AZ_VNET_CIDR} \
--subnet-name ${AZ_AKS_SUBNET} \
--subnet-prefixes ${AZ_AKS_SUBNET_CIDR} \
--location ${AZ_LOCATION}"

#3. Retrieve AKS subnet ID
AKS_SUBNET_ID=$(az network vnet subnet show \
	-g ${AZ_RG} \
	--vnet-name ${AZ_VNET} \
	--name ${AZ_AKS_SUBNET} \
	--query id -o tsv)

#4. Create additional subnets
printcmd "Creating VM subnet"
runcmd "az network vnet subnet create \
-g ${AZ_RG} \
--vnet-name ${AZ_VNET} \
-n ${AZ_VM_SUBNET} \
--address-prefix ${AZ_VM_SUBNET_CIDR}"

printcmd "Creating PE subnet"
runcmd "az network vnet subnet create \
-g ${AZ_RG} \
--vnet-name ${AZ_VNET} \
-n ${AZ_PE_SUBNET} \
--address-prefix ${AZ_PE_SUBNET_CIDR}"
runcmd "az network vnet subnet update \
-g ${AZ_RG} \
--vnet-name ${AZ_VNET} \
-n ${AZ_PE_SUBNET} \
--disable-private-endpoint-network-policies true"

#5. Create AKS cluster
#5a. Get Kubernetes non-preview version
K8_VERSION=$(az aks get-versions \
	--location ${AZ_LOCATION} \
	--query 'orchestrators[?!isPreview] | [-1].orchestratorVersion' \
	-o tsv)
#5b. Create AKS cluster
printcmd "Creating AKS cluster ${AZ_AKS_CLUSTER}"
runcmd "az aks create \
-g ${AZ_RG} \
--name ${AZ_AKS_CLUSTER} \
--node-count 2 \
--load-balancer-sku standard \
--location ${AZ_LOCATION} \
--kubernetes-version ${K8_VERSION} \
--network-plugin azure \
--vnet-subnet-id ${AKS_SUBNET_ID} \
--service-cidr ${AZ_AKS_SVC_CIDR} \
--dns-service-ip ${AZ_AKS_DNS_IP} \
--docker-bridge-address 172.17.0.1/16 \
--enable-managed-identity \
--enable-private-cluster \
--generate-ssh-keys -y"
AKS_RESOURCE_ID=$(az aks show --name ${AZ_AKS_CLUSTER} --resource-group ${AZ_RG} --query 'id' -o tsv)

#6. Create VM in vm-subnet
printcmd "Creating VM in vm-subnet"
runcmd "az vm create \
-g ${AZ_RG} \
--name test-vm \
--assign-identity \
--image UbuntuLTS \
--vnet-name ${AZ_VNET} \
--subnet ${AZ_VM_SUBNET} \
--generate-ssh-keys \
--public-ip-address \"\" \
--size Standard_DS1_v2"

#7. Create Private Endpoint 
printcmd "Creating Private Endpoint to AKS API server"
runcmd "az network private-endpoint create \
-g ${AZ_RG} \
-n ${AZ_PE_AKS_MASTER} \
--vnet-name ${AZ_VNET} \
--subnet ${AZ_PE_SUBNET} \
--private-connection-resource-id ${AKS_RESOURCE_ID} \
--group-ids management \
--connection-name \"AKSPrivateClusterConnection\""



#6. Get AKS Credentials
printcmd "Getting AKS credentials"
runcmd "az aks get-credentials \
-g ${AZ_RG} \
-n ${AZ_AKS_CLUSTER}"

#7. Print AKS Cluster Info
printcmd "AKS Cluster ${AZ_AKS_CLUSTER} created, you can now run 'kubectl' commands"
kubectl get nodes

#8. Housekeeping
cat << EOF > 99delete_az_resources.sh
#!/bin/bash

az group delete -n ${AZ_RG} -y --no-wait
EOF
