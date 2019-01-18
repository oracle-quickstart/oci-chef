module "chef_workstation" {
  source = "../nodes"

  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_workstation_name}"
  hostname_label             = "${var.chef_workstation_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = ["${var.subnet_ocid}"]
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape                      = "${var.shape}"
}

resource "null_resource" "install_chefdk" {
  triggers {
    private_ip = "${element(module.chef_workstation.private_ip, 0)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rpm -Uvh ${var.chefdk_rpm_url}",
    ]

    connection {
      host        = "${element(module.chef_workstation.private_ip, 0)}"
      type        = "ssh"
      user        = "${var.ssh_user}"
      private_key = "${var.ssh_private_key}"
      timeout     = "3m"

      bastion_host        = "${var.bastion_public_ip}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${var.bastion_private_key}"
    }
  }
}
