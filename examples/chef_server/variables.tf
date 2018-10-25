# Oracle Cloud Infrastructure Authentication details
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}

# Region
variable "region" {}

# Compartment
variable "compartment_ocid" {}

# Compute Instance Configurations
variable "instance_display_name" {}
variable "subnet_ocid" {}
variable "source_ocid" {}
variable "ssh_authorized_keys" {}
variable "vcn_ocid" {}
variable "ssh_private_key" {}

variable "block_storage_sizes_in_gbs" {
  type = "list"
  default = []
}
