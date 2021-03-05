#!/bin/bash

if [ $# -ne 2 ]; then
 echo "Usage $0 <Resource Group> <Cluster name> "
 exit 1
fi

RESOURCE_GROUP=$1
NAME=$2

if [ -f "~/.ssh/id_rsa_azure" ]; then
  echo "ssh keys exists! using the same"
else
  echo "Creating new ssh keys at ~/.ssh/id_rsa_azure"
  ssh-keygen -t rsa -f ~/.ssh/id_rsa_azure -b 2048 -q -P ""
fi


echo "Retreiving Cluster Resource group"
CLUSTER_RESOURCE_GROUP=$(az aks show --resource-group $RESOURCE_GROUP --name $NAME --query nodeResourceGroup -o tsv)

echo "Retrieving scale set name"
SCALE_SET_NAME=$(az vmss list --resource-group $CLUSTER_RESOURCE_GROUP --query '[1].name' -o tsv)

echo "pushing id_rsa_azure keys on vm scalesets"
az vmss extension set  \
    --resource-group $CLUSTER_RESOURCE_GROUP \
    --vmss-name $SCALE_SET_NAME \
    --name VMAccessForLinux \
    --publisher Microsoft.OSTCExtensions \
    --version 1.4 \
    --protected-settings "{\"username\":\"azureuser\", \"ssh_key\":\"$(cat ~/.ssh/id_rsa_azure.pub)\"}"

echo "updating keys on  all instances in scaleset "
az vmss update-instances --instance-ids '*' \
    --resource-group $CLUSTER_RESOURCE_GROUP \
    --name $SCALE_SET_NAME

echo "Install ssh-jump plugin via https://krew.sigs.k8s.io/docs/user-guide/setup/install/"
echo "Run 'kubectl ssh-jump <worker-node>  -u azureuser -i ~/.ssh/id_rsa_azure -p ~/.ssh/id_rsa_azure.pub --cleanup-jump'"
