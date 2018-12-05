# How to run test cases
- Copy terraform.tfvars.template to terrafrom.tfvars in the terraform working directory, replace the key value to your own in terraform.tfvars
- Add go tool argument: -timeout 30m  <-run regexp>
## Example
```
go test -timeout 30m -run QuickStart
```
# Debug validate stage locally
- Run terraform init
- Run terraform apply --auto-approve in your terraform working directory
- Add environment parameters:SKIP_terraform_init=true;SKIP_terraform_destroy=true
## Example
```
cd ../Example/Quick_Start
terraform init
terraform apply --auto-approve
SKIP_terraform_init=true SKIP_terraform_destroy=true go test -timeout 30m -run QuickStart
```