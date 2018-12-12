module "chef_server" {
  source                   = "modules/chef_server"
  compartment_ocid         = "${var.compartment_ocid}"
  chef_server_name         = "${var.chef_server_name}"
  source_ocid              = "${var.source_ocid}"
  vcn_ocid                 = "${var.vcn_ocid}"
  subnet_ocid              = "${var.subnet_ocid}"
  ssh_user                 = "${var.ssh_user}"
  ssh_authorized_keys      = "${var.ssh_authorized_keys}"
  shape                    = "${var.shape}"
  ssh_private_key          = "${var.ssh_private_key}"
  bastion_public_ip        = "${var.bastion_public_ip}"
  bastion_user             = "${var.bastion_user}"
  bastion_private_key      = "${var.bastion_private_key}"
  chef-server-core_rpm_url = "${var.chef-server-core_rpm_url}"
}

module "chef_workstation" {
  source                = "modules/chef_workstation"
  compartment_ocid      = "${var.compartment_ocid}"
  chef_workstation_name = "${var.chef_workstation_name}"
  source_ocid           = "${var.source_ocid}"
  vcn_ocid              = "${var.vcn_ocid}"
  subnet_ocid           = "${var.subnet_ocid}"
  ssh_user              = "${var.ssh_user}"
  ssh_authorized_keys   = "${var.ssh_authorized_keys}"
  shape                 = "${var.shape}"
  ssh_private_key       = "${var.ssh_private_key}"
  bastion_public_ip     = "${var.bastion_public_ip}"
  bastion_user          = "${var.bastion_user}"
  bastion_private_key   = "${var.bastion_private_key}"
  chefdk_rpm_url        = "${var.chefdk_rpm_url}"
}

resource "null_resource" "chef_server_create_user_and_org" {
  triggers {
    instance_ip = "${element(module.chef_server.private_ip,0 )}"
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
      host        = "${element(module.chef_server.private_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "3m"

      bastion_host        = "${var.bastion_public_ip}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file(var.bastion_private_key)}"
    }
  }
}

resource "null_resource" "chef_workstation_config" {
  triggers {
    instance_ip = "${element(module.chef_workstation.private_ip, 0)}"
  }

  depends_on = [
    "null_resource.chef_server_create_user_and_org",
  ]

  connection {
    host        = "${element(module.chef_workstation.private_ip, 0)}"
    type        = "ssh"
    user        = "${var.ssh_user}"
    private_key = "${file(var.ssh_private_key)}"
    timeout     = "3m"

    bastion_host        = "${var.bastion_public_ip}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
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
      "chmod 600 /home/opc/.ssh/id_rsa",
      "scp -q -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null opc@${module.chef_server.fqdn}:/home/opc/${var.chef_user_name}.pem ./${var.chef_user_name}.pem",
      "scp -q -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null opc@${module.chef_server.fqdn}:/home/opc/${var.chef_org_short_name}-validator.pem ./${var.chef_org_short_name}-validator.pem",
      "cat <<'EOF' > config.rb",
      "current_dir = File.dirname(__FILE__)",
      "log_level                :info",
      "log_location             STDOUT",
      "node_name                \"${var.chef_user_name}\"",
      "client_key               \"#{current_dir}/${var.chef_user_name}.pem\"",
      "validation_client_name   \"${var.chef_org_short_name}-validator\"",
      "validation_key           \"#{current_dir}/${var.chef_org_short_name}-validator.pem\"",
      "chef_server_url          \"https://${module.chef_server.fqdn}/organizations/${var.chef_org_short_name}\"",
      "EOF",
    ]
  }
}
