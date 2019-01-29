# How to run test cases
- Copy terraform.tfvars.template to terraform.tfvars in the terraform working directory, replace the key values to your own in terraform.tfvars
- Generate inputs_config.json file according to inputs.go. If use JSON format configuration, it will overwrite parameters in terraform.tfvars
- Add go tool argument: -timeout 30m  <-run regexp>
- Bare Metal test case default shape is BM.HighIO1.36 , or read from environment parameter: BARE_METAL_SHAPE
- Json config file default value is inputs_config.json , or read from environment parameter: JSON_CONFIG_FILE
- Support environment parameters, and will overwrite parameters in terraform.tfvars & inputs_config.json
  - TF_VAR_tenancy_ocid
  - TF_VAR_user_ocid
  - TF_VAR_fingerprint
  - TF_VAR_private_key_path
  - TF_VAR_region
  - TF_VAR_compartment_ocid
  - TF_VAR_chef_user_password
  - BARE_METAL_SHAPE
  - JSON_CONFIG_FILE
## Example
```bash
go get -t
BARE_METAL_SHAPE=BM.Standard1.36 go test -timeout 30m -run QuickStart
```
# Debug validate stage locally
- Run ```terraform init```
- Run ```terraform apply --auto-approve``` in your terraform working directory
- Add environment parameters:SKIP_terraform_init=true;SKIP_terraform_destroy=true
## Example
```bash
cd ../Example/Quick_Start
terraform init
terraform apply --auto-approve
GOCACHE=off SKIP_terraform_init=true SKIP_terraform_destroy=true go test -timeout 30m -run QuickStart$
```