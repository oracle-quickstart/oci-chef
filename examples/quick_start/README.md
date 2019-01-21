# Quick Start
## About
- Creates a VCN in Oracle Cloud Infrastructure including route table, security list and subnets from scratch. 
- Generate SSH keys.
- Create a bastion host.
- Use terraform-oci-chef module to deploy Chef Sever & Workstation
- Create three Chef Nodes by default
- Upload example_webserver cookbook from Chef Workstation
- Run recipes [example_webserver::default] on Chef Nodes
 
This configuration generally implements this:
![Chef architecture](https://objectstorage.us-phoenix-1.oraclecloud.com/n/dxterraformdev/b/doc_image/o/b0008630-895b-4a70-99ba-7d8c14e12eb1.png)

### Using this example
Copy terraform.tfvars.template to terraform.tfvars and update required information.

### Deploy  
Initialize Terraform:
```bash
terraform init
```
View what Terraform plans do before actually doing it:
```bash
terraform plan
```
Use Terraform to Provision resources and Jenkins cluster on OCI:
```bash
terraform apply
```