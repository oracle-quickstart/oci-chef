# Quickstart

## About

This example demonstrates the following tasks:

- Create a VCN including route table, security list and subnets. 
- Generate SSH keys.
- Create a bastion host.
- Use terraform-oci-chef module to deploy Chef Server & Workstation
 
This example implements the following architecture:
![Chef architecture](images/example.png)

### Using this example

Copy terraform.tfvars.template to terraform.tfvars and update required information.

### Deploy  

Initialize Terraform:
```bash
terraform init
```
View Terraform plans (without executing):
```bash
terraform plan
```
Use Terraform to provision resources and Jenkins cluster:
```bash
terraform apply
```