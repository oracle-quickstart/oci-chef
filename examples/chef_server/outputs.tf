output "instance_id" {
  description = "ocid of created instances. "

  value = [
    "${module.instance.instance_id}",
  ]
}

output "private_ip" {
  description = "Private IPs of created instances. "

  value = [
    "${module.instance.private_ip}",
  ]
}

output "public_ip" {
  description = "Public IPs of created instances. "

  value = [
    "${module.instance.public_ip}",
  ]
}
