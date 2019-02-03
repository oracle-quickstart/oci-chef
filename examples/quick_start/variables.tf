variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

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

variable "chef_vcn_display_name" {
  default = "chef"
}

variable "bastion_vcn_display_name" {
  default = "bastion"
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

variable "shape" {
  default = "VM.Standard2.1"
}

variable "ssh_user" {
  default = "opc"
}

# Bastion
variable "bastion_user" {
  description = "The SSH user to connect to the bastion host."
  default     = "opc"
}

variable "bastion_shape" {
  default = "VM.Standard2.1"
}

variable "os_chef_bucket_name" {
  default = ""
}

variable "os_ssk_key_bucket_name" {
  default = ""
}

variable "bastion_ad" {
  default = 0
}

variable "chef_ad" {
  default = 0
}
