output "instance_id" {
  description = "ocid of created chef server. "

  value = [
    "${module.chef_workstation.instance_id}",
  ]
}

output "private_ip" {
  description = "Private IPs of created instances. "

  value = [
    "${module.chef_workstation.private_ip}",
  ]
}
