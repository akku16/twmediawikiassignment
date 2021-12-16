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
  echo "keygen  -> Generate keys for logging inside VMs provisioned"
  echo "config  -> Run ansible project to configure mediawiki"
  echo "destroy -> Destroy all terraform resources"
  echo "keydist -> Distrubute keys to VMs"
  exit
fi

PROJECT_ROOT=`pwd`
SCRIPTS_PATH="$PROJECT_ROOT/scripts"
ANSIBLE_PATH="$PROJECT_ROOT/ansible"
TERRAFORM_PATH="$PROJECT_ROOT/terraform"

if [[ $operation == "deploy" ]];then

  # Create storage account of maintaing the backend of terraform
  cd $SCRIPTS_PATH && ./setup_storage_account.sh && cd -
  # Provision Infrastructure
  cd $TERRAFORM_PATH && terraform init && terraform apply && cd -
  # Generate public-private keys for ansible
  cd $SCRIPTS_PATH && ./generate_keys.sh && cd -
  echo "===> Distrubute public keys to VMs"
  cd $SCRIPTS_PATH
  while read vm; do
    if [[ ! $vm == *"["* ]];then
      ./login.expect akshar@$vm
    fi
  done <../ansible/mediawiki_inventory.ini
  cd -
  # Step 5 -> Configure using ansible
    if [[ -z $tag ]];then
    args=""
  else
    args="--tags $tag"
  fi
  cd $ANSIBLE_PATH && ansible-playbook -i mediawiki_inventory.ini deploy.yml $args && cd -

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
  echo "====> Destroying terraform resources"
   cd $TERRAFORM_PATH && terraform init && terraform destroy && cd -

elif [[ $operation == "storage" ]];then
  cd $SCRIPTS_PATH && ./setup_storage_account.sh && cd -

elif [[ $operation == "keygen" ]];then
  cd $SCRIPTS_PATH && ./generate_keys.sh && cd -

elif [[ $operation == "keydist" ]];then
  echo "Can only be done once the ansible inventory file is generated. Do you want to continue?Y/N"
  read response
  if [[ $response == "Y" ]];then
    cd $SCRIPTS_PATH
    while read vm; do
      if [[ ! $vm == *"["* ]];then
        ./login.expect akshar@$vm
      fi
    done <../ansible/mediawiki_inventory.ini
    cd -
  else
    exit
  fi

elif [[ $operation == "config" ]];then
  echo "====> Running Ansible playbooks to deploy mediawiki components"
  if [[ -z $tag ]];then
    args=""
  else
    args="--tags $tag"
  fi
  cd $ANSIBLE_PATH && ansible-playbook -i mediawiki_inventory.ini deploy.yml $args && cd -
fi