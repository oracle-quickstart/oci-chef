module "chef_server" {
  source                     = "../../"
  compartment_ocid           = "${var.compartment_ocid}"
  chef_server_name           = "${var.chef_server_display_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${var.subnet_ocid}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
  ssh_private_key            = "${var.ssh_private_key}"
}

module "chef_workstation" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "1.0.1"

  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_workstation_display_name}"
  hostname_label             = "${var.chef_workstation_display_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${var.subnet_ocid}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
}

module "chef_node" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "1.0.1"

  instance_count             = "${var.chef_node_count}"
  compartment_ocid           = "${var.compartment_ocid}"
  instance_display_name      = "${var.chef_node_display_name}"
  source_ocid                = "${var.source_ocid}"
  vcn_ocid                   = "${var.vcn_ocid}"
  subnet_ocid                = "${var.subnet_ocid}"
  ssh_authorized_keys        = "${var.ssh_authorized_keys}"
  block_storage_sizes_in_gbs = "${var.block_storage_sizes_in_gbs}"
}

data "local_file" "user_key" {
  filename = "./${var.chef_user_name}.pem"

  depends_on = [
    "null_resource.chef_server_creat_user_and_org",
  ]
}

resource "null_resource" "chef_server_creat_user_and_org" {
  triggers {
    instance_ip = "${element(module.chef_server.public_ip,0 )}"
  }

  depends_on = [
    "module.chef_server",
  ]

  provisioner "remote-exec" {
    inline = [
      "sudo chef-server-ctl user-create ${var.chef_user_name} ${var.chef_user_fist_name} ${var.chef_user_last_name} ${var.chef_user_email} '${var.chef_user_password}' --filename /home/opc/${var.chef_user_name}.pem",
      "sudo chef-server-ctl org-create ${var.chef_org_short_name} '${var.chef_org_full_name}' --association_user ${var.chef_user_name} --filename /home/opc/${var.chef_org_short_name}-validator.pem",
    ]

    connection {
      host        = "${element(module.chef_server.public_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"
    }
  }

  provisioner "local-exec" {
    command = "scp -q -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key} opc@${element(module.chef_server.public_ip, 0)}:/home/opc/${var.chef_user_name}.pem ./${var.chef_user_name}.pem"
  }

  provisioner "local-exec" {
    when       = "destroy"
    on_failure = "continue"
    command    = "rm ./${var.chef_user_name}.pem"
  }
}

resource "null_resource" "chef_workstation_install_rpm_and_config" {
  triggers {
    instance_ip = "${element(module.chef_workstation.public_ip, 0)}"
  }

  depends_on = [
    "null_resource.chef_server_creat_user_and_org",
  ]

  provisioner "file" {
    source      = "${var.ssh_private_key}"
    destination = "~/.ssh/id_rsa"

    connection {
      host        = "${element(module.chef_workstation.public_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install git -y",
      "wget https://packages.chef.io/files/stable/chefdk/3.3.23/el/7/chefdk-3.3.23-1.el7.x86_64.rpm",
      "sudo rpm -Uvh chefdk-3.3.23-1.el7.x86_64.rpm",
      "rm chefdk-3.3.23-1.el7.x86_64.rpm",
      "mkdir .chef",
      "cd .chef",
      "chmod 400 /home/opc/.ssh/id_rsa",
      "scp -q -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null opc@${module.chef_server.fqdn}:/home/opc/${var.chef_user_name}.pem ./${var.chef_user_name}.pem",
      "cat <<'EOF' > knife.rb",
      "current_dir = File.dirname(__FILE__)",
      "log_level                :info",
      "log_location             STDOUT",
      "node_name                \"${var.chef_user_name}\"",
      "client_key               \"#{current_dir}/${var.chef_user_name}.pem\"",
      "chef_server_url          \"https://${module.chef_server.fqdn}/organizations/${var.chef_org_short_name}\"",
      "EOF",
      "cd ~",
      "git clone https://github.com/oracle/terraform-examples",
      "cd /home/opc/terraform-examples/examples/oci/chef/cookbooks/example_webserver",
      "knife ssl fetch",
      "berks install",
      "berks upload",
    ]

    connection {
      host        = "${element(module.chef_workstation.public_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"
    }
  }
}

resource "null_resource" "chef_node_run_recipes" {
  triggers {
    instance_ip = "${element(module.chef_node.public_ip, count.index)}"
  }

  depends_on = [
    "null_resource.chef_workstation_install_rpm_and_config",
  ]

  count = "${var.chef_node_count}"

  provisioner "chef" {
    server_url              = "https://${module.chef_server.fqdn}/organizations/${var.chef_org_short_name}"
    node_name               = "${var.chef_node_name}_${count.index}"
    run_list                = "${var.chef_recipes}"
    user_name               = "${var.chef_user_name}"
    user_key                = "${data.local_file.user_key.content}"
    recreate_client         = true
    fetch_chef_certificates = true

    connection {
      host        = "${element(module.chef_node.public_ip, count.index)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"
    }
  }

  provisioner "remote-exec" {
    when       = "destroy"
    on_failure = "continue"

    inline = [
      "knife node delete ${var.chef_node_name}_${count.index} -y",
    ]

    connection {
      host        = "${element(module.chef_workstation.public_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"
    }
  }
}
