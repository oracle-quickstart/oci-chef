module "chef_node_subnet1" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "1.0.1"

  instance_count             = "${var.chef_node_count}"
  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_node_display_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${element(var.subnet_ocid,0)}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape="${var.shape}"
}
module "chef_node_subnet2" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "1.0.1"

  instance_count             = "${var.chef_node_count}"
  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_node_display_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                =  "${element(var.subnet_ocid,1)}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape="${var.shape}"
}
module "chef_node_subnet3" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "1.0.1"

  instance_count             = "${var.chef_node_count}"
  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_node_display_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${element(var.subnet_ocid,2)}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape="${var.shape}"
}
