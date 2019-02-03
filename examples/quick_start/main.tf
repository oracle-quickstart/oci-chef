resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

module "chef" {
  source              = "../../"
  region              = "${var.region}"
  compartment_ocid    = "${var.compartment_ocid}"
  source_ocid         = "${var.source_ocid[var.region]}"
  vcn_ocid            = "${oci_core_virtual_network.chef.id}"
  subnet_ocid         = "${oci_core_subnet.chef.0.id}"
  ssh_user            = "${var.ssh_user}"
  ssh_authorized_keys = "${tls_private_key.ssh_key.public_key_openssh}"
  ssh_private_key     = "${tls_private_key.ssh_key.private_key_pem}"
  shape               = "${var.shape}"
  bastion_public_ip   = "${element(module.bastion_host.public_ip, 0)}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${tls_private_key.ssh_key.private_key_pem}"
  chef_user_name      = "${var.chef_user_name}"
  chef_user_fist_name = "${var.chef_user_fist_name}"
  chef_user_last_name = "${var.chef_user_last_name}"
  chef_user_password  = "${var.chef_user_password}"
  chef_user_email     = "${var.chef_user_email}"
  chef_org_short_name = "${var.chef_org_short_name}"
  chef_org_full_name  = "${var.chef_org_full_name}"
  os_chef_bucket_name = "${coalesce(var.os_chef_bucket_name,random_id.chef_bucket_name.hex)}"
}

module "bastion_host" {
  source                = "../../modules/nodes"
  compartment_ocid      = "${var.compartment_ocid}"
  instance_display_name = "bastion"
  hostname_label        = "bastion"
  source_ocid           = "${var.source_ocid[var.region]}"
  vcn_ocid              = "${oci_core_virtual_network.bastion.id}"
  subnet_ocid           = ["${oci_core_subnet.bastion.id}"]
  ssh_authorized_keys   = "${tls_private_key.ssh_key.public_key_openssh}"
  shape                 = "${var.bastion_shape}"
}
