output "instance_id" {
  description = "ocid of created chef nodes. "

  value = [
    "${concat(module.chef_node_subnet1.instance_id,module.chef_node_subnet2.instance_id,module.chef_node_subnet3.instance_id)}",
  ]
}

output "private_ip" {
  description = "Private IPs of created chef nodes. "

  value = [
    "${concat(module.chef_node_subnet1.private_ip,module.chef_node_subnet2.private_ip,module.chef_node_subnet3.private_ip)}",
  ]
}

output "public_ip" {
  description = "Public IPs of created chef nodes. "

  value = [
    "${concat(module.chef_node_subnet1.public_ip,module.chef_node_subnet2.public_ip,module.chef_node_subnet3.public_ip)}",
  ]
}