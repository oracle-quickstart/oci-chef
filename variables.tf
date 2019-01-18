variable "compartment_ocid" {}

variable "chef_server_name" {
  default = "chefserver"
}

variable "chef_workstation_name" {
  default = "chefworkstation"
}

variable "subnet_ocid" {}
variable "source_ocid" {}

variable "ssh_authorized_keys" {
  description = "Public SSH keys content in the ~/.ssh/authorized_keys file for the default user on the instance."
}

variable "vcn_ocid" {}

variable "ssh_user" {
  default = "opc"
}

variable "ssh_private_key" {
  description = "The private SSH key content to access instance."
}

variable "shape" {
  default = "VM.Standard2.1"
}

# Bastion
variable "bastion_public_ip" {}

variable "bastion_user" {}

variable "bastion_private_key" {
  description = "The private SSH key content to access instance."
}

# Chef user & org
variable "chef_user_name" {}

variable "chef_user_fist_name" {}
variable "chef_user_last_name" {}
variable "chef_user_password" {}
variable "chef_user_email" {}
variable "chef_org_short_name" {}
variable "chef_org_full_name" {}

# Chef RPMs
variable "chef-server-core_rpm_url" {
  default = "https://packages.chef.io/files/stable/chef-server/12.18.14/el/7/chef-server-core-12.18.14-1.el7.x86_64.rpm"
}

variable "chefdk_rpm_url" {
  default = "https://packages.chef.io/files/stable/chefdk/3.3.23/el/7/chefdk-3.3.23-1.el7.x86_64.rpm"
}
