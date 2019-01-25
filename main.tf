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
  chefdk_rpm_url           = "${var.chefdk_rpm_url}"
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

resource "tls_private_key" "chef_org" {
  algorithm = "RSA"
}

resource "local_file" "chef_org_private_key_pem" {
  filename = "${var.chef_org_short_name}-validator.pem"
  content  = "${tls_private_key.chef_org.private_key_pem}"
}

resource "tls_private_key" "chef_user" {
  algorithm = "RSA"
}

resource "local_file" "chef_user_private_key_pem" {
  filename = "${var.chef_user_name}.pem"
  content  = "${tls_private_key.chef_user.private_key_pem}"
}

resource "null_resource" "chef_server_create_user_and_org" {
  triggers {
    instance_ip = "${element(module.chef_server.private_ip,0 )}"
  }

  depends_on = [
    "module.chef_server",
    "tls_private_key.chef_org",
    "tls_private_key.chef_user",
  ]

  provisioner "remote-exec" {
    inline = [
      "if [ ! -d \".chef\" ]; then",
      "mkdir .chef",
      "fi",
      "sudo chef-server-ctl user-create ${var.chef_user_name} ${var.chef_user_fist_name} ${var.chef_user_last_name} ${var.chef_user_email} '${var.chef_user_password}' --filename .chef/${var.chef_user_name}.pem",
      "sudo chef-server-ctl org-create ${var.chef_org_short_name} '${var.chef_org_full_name}' --association_user ${var.chef_user_name} --filename .chef/${var.chef_org_short_name}-validator.pem",
      "cat <<'EOF' > .chef/user.pub",
      "${tls_private_key.chef_user.public_key_pem}",
      "EOF",
      "cat <<'EOF' > .chef/org.pub",
      "${tls_private_key.chef_org.public_key_pem}",
      "EOF",
      "cat <<'EOF' > .chef/config.rb",
      "current_dir = File.dirname(__FILE__)",
      "log_level                :info",
      "log_location             STDOUT",
      "node_name                \"${var.chef_user_name}\"",
      "client_key               \"#{current_dir}/${var.chef_user_name}.pem\"",
      "chef_server_url          \"https://${module.chef_server.fqdn}/organizations/${var.chef_org_short_name}\"",
      "knife[:editor] = \"/usr/bin/vim\"",
      "EOF",
      "knife ssl fetch",
      "knife user key create ${var.chef_user_name}  --public-key .chef/user.pub -d",
      "knife client key edit ${var.chef_org_short_name}-validator default --public-key .chef/org.pub -d",
    ]

    connection {
      host        = "${element(module.chef_server.private_ip, 0)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${var.ssh_private_key}"
      timeout     = "5m"

      bastion_host        = "${var.bastion_public_ip}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${var.bastion_private_key}"
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
    private_key = "${var.ssh_private_key}"
    timeout     = "5m"

    bastion_host        = "${var.bastion_public_ip}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${var.bastion_private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "if [ ! -d \".chef\" ]; then",
      "mkdir .chef",
      "fi",
      "cat <<'EOF' > .chef/${var.chef_user_name}.pem",
      "${tls_private_key.chef_user.private_key_pem}",
      "EOF",
      "cat <<'EOF' > .chef/${var.chef_org_short_name}-validator.pem",
      "${tls_private_key.chef_org.private_key_pem}",
      "EOF",
      "cat <<'EOF' > .chef/config.rb",
      "current_dir = File.dirname(__FILE__)",
      "log_level                :info",
      "log_location             STDOUT",
      "node_name                \"${var.chef_user_name}\"",
      "client_key               \"#{current_dir}/${var.chef_user_name}.pem\"",
      "validation_client_name   \"${var.chef_org_short_name}-validator\"",
      "validation_key           \"#{current_dir}/${var.chef_org_short_name}-validator.pem\"",
      "chef_server_url          \"https://${module.chef_server.fqdn}/organizations/${var.chef_org_short_name}\"",
      "knife[:editor] = \"/usr/bin/vim\"",
      "EOF",
      "knife ssl fetch",
    ]
  }
}
