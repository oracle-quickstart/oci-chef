############################################
# Create Chef VCN
############################################
resource "oci_core_virtual_network" "chef" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.chef_vcn_display_name}"
  cidr_block     = "10.0.0.0/24"
  dns_label      = "chef"
}

############################################
# Create Bastion VCN
############################################
resource "oci_core_virtual_network" "bastion" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.bastion_vcn_display_name}"
  cidr_block     = "172.16.0.0/24"
  dns_label      = "bastion"
}

############################################
# Create Internet Gateway
############################################
resource "oci_core_internet_gateway" "ig" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.bastion.id}"
}

############################################
# Create NAT Gateway
############################################
resource "oci_core_nat_gateway" "ng" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"
}

############################################
# Create Route Table
############################################
resource "oci_core_route_table" "bastion" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.bastion.id}"
  display_name   = "public"

  route_rules = [{
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.ig.id}"
  },
    {
      destination       = "${oci_core_virtual_network.chef.cidr_block}"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = "${oci_core_local_peering_gateway.bastion.id}"
    },
  ]
}

resource "oci_core_route_table" "chef" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"
  display_name   = "private"

  route_rules = [{
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_nat_gateway.ng.id}"
  },
    {
      destination       = "${oci_core_virtual_network.bastion.cidr_block}"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = "${oci_core_local_peering_gateway.chef.id}"
    },
  ]
}

############################################
# Create Security List
############################################
resource "oci_core_security_list" "chef" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "6"
  }]

  ingress_security_rules = [{
    tcp_options = {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "${oci_core_virtual_network.bastion.cidr_block}"
  },
    {
      tcp_options = {
        "max" = 22
        "min" = 22
      }

      protocol = "6"
      source   = "${oci_core_virtual_network.chef.cidr_block}"
    },
    {
      tcp_options = {
        "max" = "443"
        "min" = "443"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options = {
        "max" = "80"
        "min" = "80"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
  ]
}

resource "oci_core_security_list" "bastion" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.bastion.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "6"
  }]

  ingress_security_rules = [{
    tcp_options = {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }]
}

############################################
# Datasource
############################################
# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = "${var.tenancy_ocid}"
}

############################################
# Create Bastion Subnet
############################################
resource "oci_core_subnet" "bastion" {
  depends_on = ["data.oci_identity_availability_domains.ads"]

  //availability_domain = "${data.template_file.ad_names.*.rendered[length(data.template_file.ad_names.*.rendered) - 1]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[0], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  cidr_block          = "${cidrsubnet(oci_core_virtual_network.bastion.cidr_block, 6 , 0)}"
  security_list_ids   = ["${oci_core_security_list.bastion.id}"]
  vcn_id              = "${oci_core_virtual_network.bastion.id}"
  route_table_id      = "${oci_core_route_table.bastion.id}"
  dns_label           = "bastion"
}

############################################
# Create chef Subnets
############################################
resource "oci_core_subnet" "chef" {
  //count                      = "${length(data.template_file.ad_names.*.rendered)}"
  depends_on          = ["data.oci_identity_availability_domains.ads"]
  count               = "${length(data.oci_identity_availability_domains.ads.availability_domains)}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[count.index], "name")}"

  //availability_domain        = "${data.template_file.ad_names.*.rendered[count.index]}"
  cidr_block                 = "${cidrsubnet(oci_core_virtual_network.chef.cidr_block, 2 , count.index)}"
  security_list_ids          = ["${oci_core_security_list.chef.id}"]
  compartment_id             = "${var.compartment_ocid}"
  vcn_id                     = "${oci_core_virtual_network.chef.id}"
  route_table_id             = "${oci_core_route_table.chef.id}"
  dns_label                  = "ad${count.index + 1}"
  prohibit_public_ip_on_vnic = true
}

############################################
# Create Local Peering Gateway
############################################
resource "oci_core_local_peering_gateway" "bastion" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.bastion.id}"
  peer_id        = "${oci_core_local_peering_gateway.chef.id}"
}

resource "oci_core_local_peering_gateway" "chef" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"
}
