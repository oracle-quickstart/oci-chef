variable "compartment_ocid" {}
variable "subnet_ocid" {
  type    = "list"
}
variable "source_ocid" {}
variable "ssh_authorized_keys" {}
variable "vcn_ocid" {}
variable "block_storage_sizes_in_gbs" {
  type    = "list"
  default = []
}
#Chef node configation
variable "chef_node_display_name" {
  default = "chefnode"
}

variable "chef_node_count" {
  default = 1
}
variable "shape" {
  default = "VM.Standard1.1"
}