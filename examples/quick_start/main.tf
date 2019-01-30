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

module "chef_node" {
  source = "../../modules/nodes"

  instance_display_name = "chefnode"
  instance_count        = "${var.chef_node_count}"
  compartment_ocid      = "${var.compartment_ocid}"
  source_ocid           = "${var.source_ocid[var.region]}"
  vcn_ocid              = "${oci_core_virtual_network.chef.id}"
  subnet_ocid           = "${oci_core_subnet.chef.*.id}"
  ssh_authorized_keys   = "${tls_private_key.ssh_key.public_key_openssh}"
  shape                 = "${var.shape}"
}

module "bastion_host" {
  source = "../../modules/nodes"

  compartment_ocid      = "${var.compartment_ocid}"
  instance_display_name = "bastion"
  hostname_label        = "bastion"
  source_ocid           = "${var.source_ocid[var.region]}"
  vcn_ocid              = "${oci_core_virtual_network.bastion.id}"
  subnet_ocid           = ["${oci_core_subnet.bastion.id}"]
  ssh_authorized_keys   = "${tls_private_key.ssh_key.public_key_openssh}"
  shape                 = "${var.bastion_shape}"
}

locals {
  cookbooks_path = "${path.module}/cookbooks"
}

resource "null_resource" "upload_cookbooks" {
  depends_on = [
    "module.chef",
  ]

  connection {
    host        = "${element(module.chef.chef_workstation_private_ip, 0)}"
    type        = "ssh"
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh_key.private_key_pem}"
    timeout     = "5m"

    bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${tls_private_key.ssh_key.private_key_pem}"
  }

  provisioner "file" {
    destination = "/home/opc"
    source      = "${local.cookbooks_path}"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/opc/cookbooks/example_webserver",
      "berks install",
      "berks upload",
    ]
  }
}

resource "null_resource" "chef_node_run_recipes" {
  triggers {
    instance_ip = "${element(module.chef_node.private_ip, count.index)}"
  }

  depends_on = [
    "null_resource.upload_cookbooks",
  ]

  count = "${var.chef_node_count}"

  provisioner "chef" {
    server_url = "https://${module.chef.chef_server_fqdn}/organizations/${var.chef_org_short_name}"
    node_name  = "${var.chef_node_name}_${count.index}"
    run_list   = "${var.chef_recipes}"
    user_name  = "${var.chef_user_name}"

    user_key                = "${data.oci_objectstorage_object.chef_user_name_pem.content}"
    recreate_client         = true
    fetch_chef_certificates = true

    connection {
      host        = "${element(module.chef_node.private_ip, count.index)}"
      type        = "ssh"
      user        = "${var.ssh_user}"
      private_key = "${tls_private_key.ssh_key.private_key_pem}"
      timeout     = "5m"

      bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${tls_private_key.ssh_key.private_key_pem}"
    }
  }

  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"

    inline = [
      "knife node delete ${var.chef_node_name}_${count.index} -y",
      "knife client delete ${var.chef_node_name}_${count.index} -y",
    ]

    connection {
      host        = "${element(module.chef.chef_workstation_private_ip, 0)}"
      type        = "ssh"
      user        = "${var.ssh_user}"
      private_key = "${tls_private_key.ssh_key.private_key_pem}"
      timeout     = "5m"

      bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${tls_private_key.ssh_key.private_key_pem}"
    }
  }
}
