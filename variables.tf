variable "compartment_ocid" {}
variable "chef_server_name" {}
variable "subnet_ocid" {}
variable "source_ocid" {}
variable "ssh_authorized_keys" {}
variable "vcn_ocid" {}
variable "ssh_private_key" {}

variable "block_storage_sizes_in_gbs" {
  type = "list"
}
