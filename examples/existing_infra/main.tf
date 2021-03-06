module "chef" {
  source              = "../../"
  region              = "${var.region}"
  compartment_ocid    = "${var.compartment_ocid}"
  source_ocid         = "${var.source_ocid[var.region]}"
  vcn_ocid            = "${var.vcn_ocid}"
  subnet_ocid         = "${var.subnet_ocid}"
  ssh_authorized_keys = "${file(var.ssh_authorized_keys)}"
  ssh_private_key     = "${file(var.ssh_private_key)}"
  shape               = "${var.shape}"
  bastion_public_ip   = "${var.bastion_public_ip}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${file(var.bastion_private_key)}"
  chef_user_name      = "${var.chef_user_name}"
  chef_user_fist_name = "${var.chef_user_fist_name}"
  chef_user_last_name = "${var.chef_user_last_name}"
  chef_user_password  = "${var.chef_user_password}"
  chef_user_email     = "${var.chef_user_email}"
  chef_org_short_name = "${var.chef_org_short_name}"
  chef_org_full_name  = "${var.chef_org_full_name}"
}

module "chef_node" {
  source = "../../modules/nodes"

  instance_display_name = "chefnode"
  instance_count        = "${var.chef_node_count}"
  compartment_ocid      = "${var.compartment_ocid}"
  source_ocid           = "${var.source_ocid[var.region]}"
  vcn_ocid              = "${var.vcn_ocid}"
  subnet_ocid           = "${var.chef_node_subnets_ocid}"
  ssh_authorized_keys   = "${file(var.ssh_authorized_keys)}"
  shape                 = "${var.shape}"
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
    timeout     = "5m"

    bastion_host        = "${var.bastion_public_ip}"
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
  ]

  count = "${var.chef_node_count}"

  provisioner "chef" {
    server_url              = "https://${module.chef.chef_server_fqdn}/organizations/${var.chef_org_short_name}"
    node_name               = "${var.chef_node_name}_${count.index}"
    run_list                = "${var.chef_recipes}"
    user_name               = "${var.chef_user_name}"
    user_key                = "${module.chef.client_key}"
    recreate_client         = true
    fetch_chef_certificates = true

    connection {
      host        = "${element(module.chef_node.private_ip, count.index)}"
      type        = "ssh"
      user        = "opc"
      private_key = "${file(var.ssh_private_key)}"
      timeout     = "5m"

      bastion_host        = "${var.bastion_public_ip}"
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
      timeout     = "5m"

      bastion_host        = "${var.bastion_public_ip}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file(var.bastion_private_key)}"
    }
  }
  os_chef_bucket_name = "${coalesce(var.os_chef_bucket_name,random_id.chef_bucket_name.hex)}"
}
