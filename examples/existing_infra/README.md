# Existing Infra
## About
- Use terraform-oci-chef module to deploy Chef Sever & Workstation
- Create three Chef Nodes by default
- Upload example_webserver cookbook from Chef Workstation
- Run recipes [example_webserver::default] on Chef Nodes
 
This configuration generally implements this:
![Chef architecture](images/example.png)

### Using this example
Copy terraform.tfvars.template to terraform.tfvars and update required information.

### Deploy  
Initialize Terraform:
```bash
terraform init
```
View what Terraform plans do before actually doing it:
```bash
terraform plan -var 'chef_user_password=yourPassword'
```
Use Terraform to Provision resources and Jenkins cluster on OCI:
```bash
terraform apply -var 'chef_user_password=yourPassword'
```

### Verification
- Create a tunnel to Chef node:```ssh -i <bastion_private_key.pem> -L 1234:<chef_node_private_ip>:80 <bastion_user>@<bastion_public_ip>```
- Run test: ```curl -w "\n" http://localhost:1234``` , expected return: _Hello World!_