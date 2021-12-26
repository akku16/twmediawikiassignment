#!/bin/bash

operation=$1
tag=$2
if [[ -z $operation ]];then
  echo "======> Please specify an operation"
  exit
fi
list_of_operations="deploy destroy init plan storage keygen apply config keydist"
echo $list_of_operations | grep -w -q $operation
if [[ $? != 0 ]];then
  echo "XXXXXXXXXX Incorrect operation"
  echo "Valid operation are - "
  echo "==============================================================="
  echo "deploy  -> Deploy whole project"
  echo "init    -> Initialize terraform project"
  echo "plan    -> See the plan of terraform project"
  echo "apply   -> provision terraform resources"
  echo "storage -> Create storage account for terraform backend"
  echo "destroy -> Destroy all terraform resources"
  exit
fi

PROJECT_ROOT=`pwd`
SCRIPTS_PATH="$PROJECT_ROOT/scripts"
ANSIBLE_PATH="$PROJECT_ROOT/ansible"
TERRAFORM_PATH="$PROJECT_ROOT/terraform"

if [[ $operation == "deploy" ]];then

  # Create storage account of maintaing the backend of terraform
  cd $SCRIPTS_PATH && ./setup_storage_account.sh Create && cd -
  # Provision Infrastructure
  cd $TERRAFORM_PATH && terraform init && terraform apply -auto-approve && cd -

elif [[ $operation == "init" ]];then
  echo "====> Initializing terraform project"
  cd $TERRAFORM_PATH && terraform init && cd -

elif [[ $operation == "plan" ]]; then
  echo "====> Creating terraform plan for resource provisioning"
  cd $TERRAFORM_PATH && terraform init && terraform plan && cd -

elif [[ $operation == "apply" ]]; then
  echo "====> Provisioning terraform resource "
  cd $TERRAFORM_PATH && terraform init && terraform apply && cd -

elif [[ $operation == "destroy" ]];then
  echo "====> Destroying resources"
   cd $TERRAFORM_PATH && terraform init && terraform destroy && cd - && cd $SCRIPTS_PATH && ./setup_storage_account.sh Destroy && cd -

elif [[ $operation == "storage" ]];then
  cd $SCRIPTS_PATH && ./setup_storage_account.sh && cd -
elif [[ $operation == "config" ]];then
  echo "====> Running Ansible playbooks to deploy mediawiki components"
  if [[ -z $tag ]];then
    args=""
  else
    args="--tags $tag"
  fi
  cd $ANSIBLE_PATH && ansible-playbook -i mediawiki_inventory.ini deploy.yml $args && cd -
fi