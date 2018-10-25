output "instance_id" {
  description = "ocid of created chef server. "

  value = [
    "${module.chef_server.instance_id}",
  ]
}

output "private_ip" {
  description = "Private IPs of created instances. "

  value = [
    "${module.chef_server.private_ip}",
  ]
}

output "public_ip" {
  description = "Public IPs of created instances. "

  value = [
    "${module.chef_server.public_ip}",
  ]
}

output "fqdn" {
  description = "chef server full qualify domain name "
  value       = "${data.oci_core_instance.chef_server.hostname_label}.${data.oci_core_subnet.chef_server_subnet.subnet_domain_name}"
}
