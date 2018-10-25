variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

variable "chef_server_display_name" {
  default = "chefserver"
}

variable "subnet_ocid" {}
variable "source_ocid" {}
variable "ssh_authorized_keys" {}
variable "vcn_ocid" {}
variable "ssh_private_key" {}

variable "block_storage_sizes_in_gbs" {
  type    = "list"
  default = []
}

#Chef server configuration
variable "chef_user_name" {}

variable "chef_user_fist_name" {}
variable "chef_user_last_name" {}
variable "chef_user_password" {}
variable "chef_user_email" {}
variable "chef_org_short_name" {}
variable "chef_org_full_name" {}

#Chef work station configation
variable "chef_workstation_display_name" {
  default = "chefworkstation"
}

#Chef node configation
variable "chef_node_display_name" {
  default = "chefnode"
}

variable "chef_node_count" {
  default = 2
}

variable "chef_recipes" {
  description = "List of recipes for Chef to run"
  type        = "list"
  default     = ["recipe[example_webserver::default]"]
}

variable "chef_node_name" {
  description = "Chef Server Node Name, must be unique"
  default     = "httpd_server"
}
