output "bastion_instance_id" {
  value = "${module.bastion_host.instance_id}"
}

output "bastion_public_ip" {
  value = "${module.bastion_host.public_ip}"
}

output "bastion_private_ip" {
  value = "${module.bastion_host.private_ip}"
}

output "chef_server_instance_id" {
  description = "ocid of created instances. "

  value = [
    "${module.chef.chef_server_instance_id}",
  ]
}

output "chef_server_private_ip" {
  description = "Private IPs of created instances. "

  value = [
    "${module.chef.chef_server_private_ip}",
  ]
}

output "chef_workstation_instance_id" {
  description = "ocid of created chef_workstation. "

  value = [
    "${module.chef.chef_workstation_instance_id}",
  ]
}

output "chef_workstation_private_ip" {
  description = "Private IPs of created chef_workstation. "

  value = [
    "${module.chef.chef_workstation_private_ip}",
  ]
}

output "ssh_user" {
  value = "${var.ssh_user}"
}

output "bastion_user" {
  value = "${var.bastion_user}"
}

output "chef" {
  value = {
    admin_user_name        = "${var.chef_user_name}"
    orgzination_short_name = "${var.chef_org_short_name}"
  }
}

output "object_storage_chef" {
  value = {
    namespace      = "${data.oci_objectstorage_namespace.os.namespace}"
    bucket         = "${lookup(module.chef.os_chef, "bucket")}"
    client_key     = "${lookup(module.chef.os_chef, "client_key")}"
    validation_key = "${lookup(module.chef.os_chef, "validation_key")}"
  }
}

output "object_storage_ssh_keys" {
  value = {
    namespace               = "${data.oci_objectstorage_namespace.os.namespace}"
    bucket                  = "${oci_objectstorage_bucket.ssh_keys.name}"
    bastion_private_key     = "${oci_objectstorage_object.bastion_private_key.object}"
    bastion_authorized_keys = "${oci_objectstorage_object.bastion_authorized_keys.object}"
    ssh_private_key         = "${oci_objectstorage_object.ssh_private_key.object}"
    ssh_authorized_keys     = "${oci_objectstorage_object.ssh_authorized_keys.object}"
  }
}

output "client_key" {
  value = "${path.module}/${module.chef.client_key}"
}

output "validation_key" {
  value = "${path.module}/${module.chef.validation_key}"
}
