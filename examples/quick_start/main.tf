module "chef" {
  source              = "../../"
  compartment_ocid    = "${var.compartment_ocid}"
  source_ocid         = "${var.source_ocid[var.region]}"
  vcn_ocid            = "${oci_core_virtual_network.chef.id}"
  subnet_ocid         = "${oci_core_subnet.chef.0.id}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  shape               = "${var.shape}"
  bastion_public_ip   = "${element(module.bastion_host.public_ip, 0)}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  chef_user_name      = "${var.chef_user_name}"
  chef_user_fist_name = "${var.chef_user_fist_name}"
  chef_user_last_name = "${var.chef_user_last_name}"
  chef_user_password  = "${var.chef_user_password}"
  chef_user_email     = "${var.chef_user_email}"
  chef_org_short_name = "${var.chef_org_short_name}"
  chef_org_full_name  = "${var.chef_org_full_name}"
}

module "chef_node" {
  source = "../../modules/chef_nodes"

  instance_display_name = "chefnode"
  instance_count        = "${var.chef_node_count}"
  compartment_ocid      = "${var.compartment_ocid}"
  source_ocid           = "${var.source_ocid[var.region]}"
  vcn_ocid              = "${oci_core_virtual_network.chef.id}"
  subnet_ocid           = "${oci_core_subnet.chef.*.id}"
  ssh_authorized_keys   = "${var.ssh_authorized_keys}"
  shape                 = "${var.shape}"
}

module "bastion_host" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "1.0.1"

  compartment_ocid      = "${var.compartment_ocid}"
  instance_display_name = "bastion"
  hostname_label        = "bastion"
  source_ocid           = "${var.source_ocid[var.region]}"
  vcn_ocid              = "${oci_core_virtual_network.chef.id}"
  subnet_ocid           = "${oci_core_subnet.bastion.id}"
  ssh_authorized_keys   = "${var.bastion_authorized_keys}"
  shape                 = "${var.shape}"
}

resource "null_resource" "bastion_install_nc" {
  triggers {
    instance_ip = "${element(module.bastion_host.public_ip, 0)}"
  }

  depends_on = ["module.bastion_host"]

  connection {
    host        = "${element(module.bastion_host.public_ip, 0)}"
    type        = "ssh"
    user        = "${var.bastion_user}"
    private_key = "${file(var.bastion_private_key)}"
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nc -y",
    ]
  }
}

data "local_file" "user_key" {
  filename = "./${var.chef_user_name}.pem"

  depends_on = [
    "null_resource.get_chef_user_key",
  ]
}

resource "null_resource" "get_chef_user_key" {
  depends_on = [
    "module.chef",
    "null_resource.bastion_install_nc",
  ]

  provisioner "local-exec" {
    command = "scp -v -q -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key} -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.bastion_private_key}  ${var.bastion_user}@${element(module.bastion_host.public_ip, 0)} nc ${element(module.chef.chef_server_private_ip, 0)} 22\" opc@${element(module.chef.chef_server_private_ip, 0)}:/home/opc/${var.chef_user_name}.pem ./${var.chef_user_name}.pem"
  }

  provisioner "local-exec" {
    when       = "destroy"
    on_failure = "continue"
    command    = "rm ./${var.chef_user_name}.pem"
  }
}

resource "null_resource" "upload_cookbooks" {
  depends_on = [
    "module.chef",
  ]

  connection {
    host        = "${element(module.chef.chef_workstation_private_ip, 0)}"
    type        = "ssh"
    user        = "opc"
    private_key = "${file(var.ssh_private_key)}"
    timeout     = "3m"

    bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install git -y",
      "if [  -d \"terraform-examples\" ]; then",
      "rm -rf terraform-examples",
      "fi",
      "git clone https://github.com/oracle/terraform-examples",
      "cd /home/opc/terraform-examples/examples/oci/chef/cookbooks/example_webserver",
      "knife ssl fetch",
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
    "null_resource.get_chef_user_key",
  ]

  count = "${var.chef_node_count}"

  provisioner "chef" {
    server_url              = "https://${module.chef.chef_server_fqdn}/organizations/${var.chef_org_short_name}"
    node_name               = "${var.chef_node_name}_${count.index}"
    run_list                = "${var.chef_recipes}"
    user_name               = "${var.chef_user_name}"
    user_key                = "${data.local_file.user_key.content}"
    recreate_client         = true
    fetch_chef_certificates = true

    connection {
      host        = "${element(module.chef_node.private_ip, count.index)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"

      bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file(var.bastion_private_key)}"
    }
  }

  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"

    inline = [
      "knife node delete ${var.chef_node_name}_${count.index} -y",
    ]

    connection {
      host        = "${element(module.chef.chef_workstation_private_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"

      bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file(var.bastion_private_key)}"
    }
  }
}
