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
