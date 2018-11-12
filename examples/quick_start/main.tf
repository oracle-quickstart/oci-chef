module "chef" {
  source                = "../../"
  compartment_ocid      = "${var.compartment_ocid}"
  chef_server_name      = "${var.chef_server_display_name}"
  chef_workstation_name = "${var.chef_workstation_display_name}"
  source_ocid           = "${var.source_ocid}"
  vcn_ocid              = "${oci_core_virtual_network.chef.id}"
  subnet_ocid           = "${oci_core_subnet.chef.0.id}"
  ssh_authorized_keys   = "${var.ssh_authorized_keys}"
  ssh_private_key       = "${var.ssh_private_key}"
  shape                 = "${var.shape}"
  bastion_public_ip     = "${element(module.bastion_host.public_ip, 0)}"
  bastion_private_key   = "${var.ssh_private_key}"
}

module "bastion_host" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "1.0.1"

  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "bastion"
  hostname_label             = "bastion"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${oci_core_virtual_network.chef.id}"
  subnet_ocid                = "${oci_core_subnet.bastion.id}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape                      = "${var.shape}"
}

module "chef_node" {
  source = "../../modules/chef_nodes"

  instance_display_name      = "chefnode"
  instance_count             = "${var.chef_node_count}"
  compartment_ocid           = "${var.compartment_ocid}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${oci_core_virtual_network.chef.id}"
  subnet_ocid                = "${oci_core_subnet.chef.*.id}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  shape                      = "${var.shape}"
}

data "local_file" "user_key" {
  filename = "./${var.chef_user_name}.pem"

  depends_on = [
    "null_resource.chef_server_creat_user_and_org",
  ]
}

resource "null_resource" "bastion_install_nc" {
  triggers {
    instance_ip = "${element(module.bastion_host.public_ip, 0)}"
  }

  depends_on = ["module.bastion_host"]

  connection {
    host        = "${element(module.bastion_host.public_ip, 0)}"
    type        = "ssh"
    user        = "opc"
    private_key = "${file(var.ssh_private_key)}"
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nc -y",
    ]
  }
}

resource "null_resource" "chef_server_creat_user_and_org" {
  triggers {
    instance_ip = "${element(module.chef.chef_server_private_ip,0 )}"
  }

  depends_on = [
    "null_resource.bastion_install_nc",
    "module.chef",
  ]

  provisioner "remote-exec" {
    inline = [
      "sudo chef-server-ctl user-create ${var.chef_user_name} ${var.chef_user_fist_name} ${var.chef_user_last_name} ${var.chef_user_email} '${var.chef_user_password}' --filename /home/opc/${var.chef_user_name}.pem",
      "sudo chef-server-ctl org-create ${var.chef_org_short_name} '${var.chef_org_full_name}' --association_user ${var.chef_user_name} --filename /home/opc/${var.chef_org_short_name}-validator.pem",
    ]

    //"sudo yum install nc -y",

    connection {
      host        = "${element(module.chef.chef_server_private_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"

      bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
      bastion_user        = "opc"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "local-exec" {
    command = "scp -v -q -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key} -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key}  opc@${element(module.bastion_host.public_ip, 0)} nc ${element(module.chef.chef_server_private_ip, 0)} 22\" opc@${element(module.chef.chef_server_private_ip, 0)}:/home/opc/${var.chef_user_name}.pem ./${var.chef_user_name}.pem"
  }

  provisioner "local-exec" {
    when       = "destroy"
    on_failure = "continue"
    command    = "rm ./${var.chef_user_name}.pem"
  }
}

resource "null_resource" "chef_workstation_config" {
  triggers {
    instance_ip = "${element(module.chef.chef_workstation_private_ip, 0)}"
  }

  depends_on = [
    "null_resource.chef_server_creat_user_and_org",
  ]

  connection {
    host        = "${element(module.chef.chef_workstation_private_ip, 0)}"
    type        = "ssh"
    user        = "opc"
    private_key = "${file(var.ssh_private_key)}"
    timeout     = "3m"

    bastion_host        = "${element(module.bastion_host.public_ip, 0)}"
    bastion_user        = "opc"
    bastion_private_key = "${file(var.ssh_private_key)}"
  }

  provisioner "file" {
    source      = "${var.ssh_private_key}"
    destination = "~/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "if [ ! -d \".chef\" ]; then",
      "mkdir .chef",
      "fi",
      "cd .chef",
      "chmod 400 /home/opc/.ssh/id_rsa",
      "scp -q -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null opc@${module.chef.chef_server_fqdn}:/home/opc/${var.chef_user_name}.pem ./${var.chef_user_name}.pem",
      "cat <<'EOF' > knife.rb",
      "current_dir = File.dirname(__FILE__)",
      "log_level                :info",
      "log_location             STDOUT",
      "node_name                \"${var.chef_user_name}\"",
      "client_key               \"#{current_dir}/${var.chef_user_name}.pem\"",
      "chef_server_url          \"https://${module.chef.chef_server_fqdn}/organizations/${var.chef_org_short_name}\"",
      "EOF",
    ]
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
    "null_resource.chef_workstation_config",
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
      bastion_user        = "opc"
      bastion_private_key = "${file(var.ssh_private_key)}"
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
      bastion_user        = "opc"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }
}
