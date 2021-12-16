# twmediawikiassignment

## Introduction
This is a working code to deploy Mediawiki on Azure using a combination of Terraform, Ansible and shell scripts

## Components
- Terraform
- Ansible
- Shell
- Azure Cli

## Pre-requisites
1. The following tools/services are required -
- Active azure subscription (Free Teir)
- Azure CLI installed
- Terraform installed
- Ansible installed
2. The following variables exported in the environment
```
export ARM_SUBSCRIPTION_ID="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ARM_TENANT_ID="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ARM_CLIENT_ID="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ARM_CLIENT_SECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export TF_VAR_vm_user="<username" #Used to create the admin user for the AzureVMs
export TF_VAR_vm_user_password="<password>" #Used to login into the AzureVMs
```  

## Implementation
- Shell Scripts
  * Master script to manage the entire deployment
  * Create the resource group, storage account, container to store the backend of terraform using Azure CLI
  * Create a access public-private key pair using keygen and distribute to all the AzureVMs
- Terraform
  * Creates a resource group
  * Creates a VNet
  * Creates two subnets (1 for Web and 1 for Database)
  * Creates two public IPs (1 for Web and 1 for Database)
  * Creates two NSGs (1 for Web and 1 for Database)
    - WEB rules 
      * SSH on 22 (inbound)
      * HTTP on 80 (inbound)
    - DB rules
      * SSH on 22 (inbound)
      * MySQL on 3306 from Web Subnet to DB Subnet (inbound)
  * Creates two NICs (1 for Web and 1 for Database)
  * Creates two Linux VMs (1 for Web and 1 for Database)
  * Generates the inventory file for ansible playbooks
- Ansible
  * Web Role
    - Installs apache2 and Mediawiki
  * DB Role
    - Installs MySql
    - Creates Database and User in MySql

## How to run 
- Ensure the points in prerequisite section are met
- Take a clone of the repo
- Change directory to `cd twmediawikiassignment`
- Run the master deploy script `./deploy.sh [operation]
  
  The list of the operations supported are as follows -
  ```
      deploy  -> Deploy whole project
      init    -> Initialize terraform project
      plan    -> See the plan of terraform project
      apply   -> provision terraform resources
      storage -> Create storage account for terraform backend
      keygen  -> Generate keys for logging inside VMs provisioned
      config  -> Run ansible project to configure mediawiki
      destroy -> Destroy all terraform resources
      keydist -> Distrubute keys to VMs
  ```
  
## Things left
- The need to automatically delete the resource group for the storage account, storage account and conatiner (Manual job as of now)
- Optimize terraform code for duplicatoin. Implement looping over variables to create resources
- Enable scalability of the solution
  * WEB component (Apache2 + Mediawiki) can be deployed in a AzureVM scale set
  * DB component can be deployed using Azure Database for MySql PaaS
- Generate a TLS key using the terraform code (Was not able to do this)
- I have added a public IP for the DB AzureVM also so that ansible could ssh and run the playbook. I think this can be improved by following ways -
  * Create the jumphost in the same VNet and run the ansible code from there (SSH using the private IP of the DB VM)
  OR
  * Presently I have a NSG rule for allowing SSH on 22 from * on DB VM. Hardcode the my local machine's IP in the source
- I wanted to orchestrate the entire deployment using azure pipelines (YAML based) but got `No hosted parallelism has been purchased or granted` error cause of a free teir account   so maybe create a self hosted build agent using terraform and use that to deploy the code
- Run the ansible roles (DB and WEB) parallely 
- I have currently stored the login password for the VMs as an ENV variable and used it in Terraform but would like to store these in Azure KV and fetch them when the need arises
  
