output "chef_server_instance_id" {
  description = "ocid of created chef server. "

  value = [
    "${module.chef_server.instance_id}",
  ]
}

output "chef_server_private_ip" {
  description = "Private IPs of created instances. "

  value = [
    "${module.chef_server.private_ip}",
  ]
}

output "chef_server_fqdn" {
  description = "chef server full qualify domain name "
  value       = "${module.chef_server.fqdn}"
}

output "chef_workstation_instance_id" {
  description = "ocid of created chef server. "

  value = [
    "${module.chef_workstation.instance_id}",
  ]
}

output "chef_workstation_private_ip" {
  description = "Private IPs of created instances. "

  value = [
    "${module.chef_workstation.private_ip}",
  ]
}

output "client_key" {
  value = "${local_file.client_key.filename}"
}

output "validation_key" {
  value = "${local_file.validation_key.filename}"
}
