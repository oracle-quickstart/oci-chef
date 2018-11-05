module "chef_server" {
  source                     = "oracle-terraform-modules/compute-instance/oci"
  version                    = "1.0.1"
  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_server_name}"
  hostname_label             = "${var.chef_server_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${var.subnet_ocid}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape ="${var.shape}"
  assign_public_ip = false
}

data "oci_core_instance" chef_server {
  instance_id = "${element(module.chef_server.instance_id, 0)}"
}

data "oci_core_subnet" chef_server_subnet {
  subnet_id = "${var.subnet_ocid}"
}

resource "null_resource" "install_rpm" {
  triggers {
    private_ip = "${element(module.chef_server.private_ip, 0)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rpm -Uvh https://packages.chef.io/files/stable/chef-server/12.18.14/el/7/chef-server-core-12.18.14-1.el7.x86_64.rpm",
      "sudo chef-server-ctl reconfigure",
      "sudo firewall-cmd --permanent --zone public --add-service http && sudo firewall-cmd --permanent --zone public --add-service https && sudo  firewall-cmd --reload",
    ]

    connection {
      host        = "${element(module.chef_server.private_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"

      bastion_host        = "${var.bastion_public_ip}"
      bastion_user        = "opc"
      bastion_private_key = "${file(var.bastion_private_key)}"
    }
  }
}
