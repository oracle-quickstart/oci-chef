module "chef_server" {
  source = "../nodes"

  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_server_name}"
  hostname_label             = "${var.chef_server_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = ["${var.subnet_ocid}"]
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape                      = "${var.shape}"
}

data "oci_core_instance" chef_server {
  instance_id = "${element(module.chef_server.instance_id, 0)}"
}

data "oci_core_subnet" chef_server_subnet {
  subnet_id = "${var.subnet_ocid}"
}

resource "null_resource" "install_chef_server_core" {
  triggers {
    private_ip = "${element(module.chef_server.private_ip, 0)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rpm -Uvh ${var.chef-server-core_rpm_url}",
      "sudo chef-server-ctl reconfigure",
      "sudo firewall-cmd --permanent --zone public --add-service http && sudo firewall-cmd --permanent --zone public --add-service https && sudo  firewall-cmd --reload",
    ]

    connection {
      host        = "${element(module.chef_server.private_ip, 0)}"
      type        = "ssh"
      user        = "${var.ssh_user}"
      private_key = "${var.ssh_private_key}"
      timeout     = "5m"

      bastion_host        = "${var.bastion_public_ip}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${var.bastion_private_key}"
    }
  }
}

resource "null_resource" "install_chefdk" {
  triggers {
    private_ip = "${element(module.chef_server.private_ip, 0)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rpm -Uvh ${var.chefdk_rpm_url}",
    ]

    connection {
      host        = "${element(module.chef_server.private_ip, 0)}"
      type        = "ssh"
      user        = "${var.ssh_user}"
      private_key = "${var.ssh_private_key}"
      timeout     = "5m"

      bastion_host        = "${var.bastion_public_ip}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${var.bastion_private_key}"
    }
  }
}
