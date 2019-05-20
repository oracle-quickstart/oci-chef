# Oracle Cloud Infrastructure Chef Terraform Module

## About
The terraform-oci-chef module allows you to deploy a Chef Server or Chef Workstation on Oracle Cloud Infrastructure using Terraform.

## Prerequisites

To use the terraform-oci-chef module, you must have the following:
- An Oracle Cloud Infrastructure account.
- A user created in that account, in a group with a policy that grants the desired permissions. This can be a user for yourself, or another person/system that needs to call the API. For an example of how to set up a new user, group, compartment, and policy, see [Adding Users](https://docs.cloud.oracle.com/iaas/Content/GSG/Tasks/addingusers.htm). For a list of typical policies you may want to use, see [Common Policies](https://docs.cloud.oracle.com/iaas/Content/Identity/Concepts/commonpolicies.htm).
- A key pair used for signing API requests, with the public key uploaded to Oracle. For more information on generating and uploading keys, see [Required Keys and OCIDs](https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm).
- Oracle Cloud Infrastructure Terraform Provider. For more information, see [Oracle Cloud Infrastructure Terraform Provider](https://www.terraform.io/docs/providers/oci/index.html). 

## Example: Deploy a Chef Server and Workstation

The following code shows how to deploy a Chef Server and Workstation using this module:

```txt
module "chef" {
  source              = "github.com/oci-quickstart/oci-quickstart-chef"
  region              = "${var.region}"
  compartment_ocid    = "${var.compartment_ocid}"
  source_ocid         = "${var.source_ocid}"
  vcn_ocid            = "${var.vcn_ocid}"
  subnet_ocid         = "${var.subnet_ocid}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  bastion_public_ip   = "${var.bastion_public_ip}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  chef_user_name      = "${var.chef_user_name}"
  chef_user_fist_name = "${var.chef_user_fist_name}"
  chef_user_last_name = "${var.chef_user_last_name}"
  chef_user_password  = "${var.chef_user_password}"
  chef_user_email     = "${var.chef_user_email}"
  chef_org_short_name = "${var.chef_org_short_name}"
  chef_org_full_name  = "${var.chef_org_full_name}"
  os_chef_bucket_name = "${var.os_chef_bucket_name}"
}
```

For more examples that demonstrate how to use this module, explore the [examples](./examples) folder. 

## Arguments

Argument | Description | Type | Default | Required
--- | --- | --- | --- | ---
region | region in which to operate, example: us-ashburn-1, us-phoenix-1. | string | n/a | yes
compartment_ocid | OCID of the compartment. | string | n/a | yes
source_ocid | OCID of an image of Oracle Enterprise Linux 7. For more information, see [Oracle Cloud Infrastructure: Images](https://docs.cloud.oracle.com/iaas/images/). | string | n/a | yes
vcn_ocid | Unique identifier (OCID) of the VCN. | string | n/a | yes
subnet_ocid |  Subnet OCID in which to place the Chef Server and Workstation instance primary VNIC. | string | n/a | yes
ssh_authorized_keys | Public SSH keys content to be included in the `~/.ssh/authorized_keys` file for the default user on the instance. | string | n/a | yes
ssh_private_key | Private key content to access the instance. | string | n/a | yes
bastion_public_ip | Bastion host public IP. | string | n/a | yes
bastion_user | Bastion host SSH login user name. | string | n/a | yes
bastion_private_key | Private key content to access bastion host. | string | n/a | yes
chef_user_name | Chef administrator user name. | string | n/a | yes
chef_user_fist_name | Chef administrator first name. | string | n/a | yes
chef_user_last_name | Chef administrator last name. | string | n/a | yes
chef_user_password | Chef administrator password. | string | n/a | yes
chef_user_email | Chef administrator E-mail address. | string | n/a | yes
chef_org_short_name | Chef organization short name. | string | n/a | yes
chef_org_full_name | Chef organization full name. | string | n/a | yes
os_chef_bucket_name | OCI Object Storage Bucket name, use it to create a new Bucket | string | n/a | yes
chef_server_name | Chef Server host name | string | "chefserver" | no
chef_workstation_name | Chef Workstation host name | string | "chefworkstation" |no
ssh_user | Chef Server and Workstation SSH login user name | string | "opc" | no
shape | Chef Server and Workstation shape | string | "VM.Standard2.1" | no
chef-server-core_rpm_url | Chef Server RPM for Enterprise Linux 7 download URL | string | "https://packages.chef.io/files/stable/chef-server/12.18.14/el/7/chef-server-core-12.18.14-1.el7.x86_64.rpm" | no
chefdk_rpm_url | Chef Workstation RPM for Enterprise Linux 7 download URL | string | "https://packages.chef.io/files/stable/chefdk/3.3.23/el/7/chefdk-3.3.23-1.el7.x86_64.rpm" | no

## Contributing

This project is open source. Oracle appreciates any contributions that are made by the open source community.

## License
Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.

Licensed under the Universal Permissive License 1.0 or Apache License 2.0.

See [LICENSE](LICENSE.txt) for more details.
