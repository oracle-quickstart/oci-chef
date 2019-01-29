variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

variable "vcn_ocid" {}
variable "subnet_ocid" {}

variable "chef_node_subnets_ocid" {
  type = "list"
}

variable "source_ocid" {
  type = "map"

  # --------------------------------------------------------------------------
  # Oracle-provided image "Oracle-Linux-7.4-2018.02.21-1"
  # See https://docs.us-phoenix-1.oraclecloud.com/images/
  # --------------------------------------------------------------------------
  default = {
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaupbfz5f5hdvejulmalhyb6goieolullgkpumorbvxlwkaowglslq"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaajlw3xfie2t5t52uegyhiq2npx7bqyu4uvi2zyu3w3mqayc2bxmaa"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa7d3fsb6272srnftyi4dphdgfjf6gurxqhmv6ileds7ba3m2gltxq"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaaa6h6gj6v4n56mqrbgnosskq63blyv2752g36zerymy63cfkojiiq"
  }
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance."
}

variable "ssh_private_key" {
  description = "The private SSH key path to access instance."
}

variable "block_storage_sizes_in_gbs" {
  type    = "list"
  default = []
}

#Chef server configuration
variable "chef_user_name" {
  default = "chefadmin"
}

variable "chef_user_fist_name" {
  default = "chef"
}

variable "chef_user_last_name" {
  default = "admin"
}

variable "chef_user_password" {}

variable "chef_user_email" {
  default = "nobody@noreply.com"
}

variable "chef_org_short_name" {
  default = "demo"
}

variable "chef_org_full_name" {
  default = "Demo Inc."
}

#Chef node configation
variable "chef_node_count" {
  default = 3
}

variable "chef_recipes" {
  description = "List of recipes for Chef to run"
  type        = "list"
  default     = ["recipe[example_webserver::default]"]
}

variable "chef_node_name" {
  description = "Chef Server Node Name, must be unique"
  default     = "httpd_server"
}

variable "shape" {
  default = "VM.Standard2.1"
}

# Bastion
variable "bastion_user" {
  description = "The SSH user to connect to the bastion host."
  default     = "opc"
}

variable "bastion_private_key" {
  description = "The private SSH key path to access instance."
}

variable "bastion_public_ip" {}

variable "os_chef_bucket_name" {
  default = "chef"
}

variable "ssh_user" {
  default = "opc"
}
