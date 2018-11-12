variable "compartment_ocid" {}
variable "chef_server_name" {}
variable "subnet_ocid" {}
variable "source_ocid" {}
variable "ssh_authorized_keys" {}
variable "vcn_ocid" {}
variable "ssh_private_key" {}

variable "block_storage_sizes_in_gbs" {
  type    = "list"
  default = []
}

variable "shape" {
  default = "VM.Standard1.1"
}

# Bastion
variable "bastion_public_ip" {}

variable "bastion_private_key" {}
