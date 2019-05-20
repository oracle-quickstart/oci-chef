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

locals {
  defaultScheme          = "https"
  DefaultHostURLTemplate = "oraclecloud.com"
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
      "sudo chef-server-ctl user-create ${var.chef_user_name} ${var.chef_user_fist_name} ${var.chef_user_last_name} ${var.chef_user_email} '${var.chef_user_password}' | curl -X PUT --data-binary @-   ${local.defaultScheme}://objectstorage.${var.region}.${local.DefaultHostURLTemplate}${oci_objectstorage_preauthrequest.upload.access_uri}${var.chef_user_name}.pem",
      "sudo chef-server-ctl org-create ${var.chef_org_short_name} '${var.chef_org_full_name}' --association_user ${var.chef_user_name} | curl -X PUT --data-binary @-    ${local.defaultScheme}://objectstorage.${var.region}.${local.DefaultHostURLTemplate}${oci_objectstorage_preauthrequest.upload.access_uri}${var.chef_org_short_name}-validator.pem",
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

resource "local_file" "ssh_private_key" {
  content  = "${var.ssh_private_key}"
  filename = "ssh_private_key"
}

resource "local_file" "bastion_private_key" {
  content  = "${var.bastion_private_key}"
  filename = "bastion_private_key"
}

data "external" "chef_keys" {
  depends_on = ["null_resource.chef_server_create_user_and_org", "local_file.ssh_private_key", "local_file.bastion_private_key"]
  program    = ["bash", "${path.module}/scripts/remote-exec"]

  query {
    bastion_host        = "${var.bastion_public_ip}"
    bastion_user        = "${var.bastion_user}"
    host                = "${element(module.chef_server.private_ip, 0)}"
    user                = "${var.ssh_user}"
    private_key         = "${local_file.ssh_private_key.filename}"
    bastion_private_key = "${local_file.bastion_private_key.filename}"
    cmd                 = "jq -n --arg client_key \"`cat /home/opc/${var.chef_user_name}.pem`\" --arg validation_key \"`cat /home/opc/${var.chef_org_short_name}-validator.pem`\" '{\"client_key\":$client_key ,\"validation_key\":$validation_key}'"
  }
}

resource "local_file" "client_key" {
  depends_on = ["data.external.chef_keys"]
  content    = "${lookup(data.external.chef_keys.result ,"client_key")}"
  filename   = "${var.chef_user_name}.pem"
}

resource "local_file" "validation_key" {
  depends_on = ["data.external.chef_keys"]
  content    = "${lookup(data.external.chef_keys.result ,"validation_key")}"
  filename   = "${var.chef_org_short_name}-validator.pem"
}

resource "null_resource" "chef_workstation_config" {
  triggers {
    instance_ip = "${element(module.chef_workstation.private_ip, 0)}"
  }

  depends_on = [
    "null_resource.chef_server_create_user_and_org",
    "data.external.chef_keys",
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
      "cd .chef",
      "cat <<EOF >  ./${var.chef_user_name}.pem",
      "${lookup(data.external.chef_keys.result ,"client_key")}",
      "EOF",
      "cat <<EOF >  ./${var.chef_org_short_name}-validator.pem",
      "${lookup(data.external.chef_keys.result ,"validation_key")}",
      "EOF",
      "cat <<'EOF' > config.rb",
      "cat <<'EOF' > .chef/${var.chef_user_name}.pem",
      "${data.oci_objectstorage_object.chef_user_name_pem.content}",
      "EOF",
      "cat <<'EOF' > .chef/${var.chef_org_short_name}-validator.pem",
      "${data.oci_objectstorage_object.chef_org_short_name_pem.content}",
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
      "knife ssl check",
    ]
  }
}
