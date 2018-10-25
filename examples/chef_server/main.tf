module "instance" {
  source                     = "../../"
  compartment_ocid           = "${var.compartment_ocid}"
  chef_server_name           = "${var.instance_display_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${var.subnet_ocid}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  ssh_private_key            = "${var.ssh_private_key}"
}
