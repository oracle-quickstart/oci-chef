module "chef_server" {
  source                     = "modules/chef_server"
  compartment_ocid           = "${var.compartment_ocid}"
  chef_server_name           = "${var.chef_server_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${var.subnet_ocid}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  shape                      = "${var.shape}"
  ssh_private_key            = "${var.ssh_private_key}"
  bastion_public_ip          = "${var.bastion_public_ip}"
  bastion_private_key        = "${var.bastion_private_key}"
}
module "chef_workstation" {
  source                     = "modules/chef_workstation"
  compartment_ocid           = "${var.compartment_ocid}"
  chef_workstation_name           = "${var.chef_workstation_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${var.subnet_ocid}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  shape                      = "${var.shape}"
  ssh_private_key            = "${var.ssh_private_key}"
  bastion_public_ip          = "${var.bastion_public_ip}"
  bastion_private_key        = "${var.bastion_private_key}"
}
