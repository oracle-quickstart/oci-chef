############################################
# Create VCN
############################################
resource "oci_core_virtual_network" "chef" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.vcn_display_name}"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "chef"
}

############################################
# Create Internet Gateway
############################################
resource "oci_core_internet_gateway" "ig" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"
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
resource "oci_core_route_table" "public" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"
  display_name   = "public"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.ig.id}"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"
  display_name   = "private"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_nat_gateway.ng.id}"
  }
}

############################################
# Create Security List
############################################
resource "oci_core_security_list" "sl" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.chef.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "6"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  },
    {
      tcp_options {
        "max" = "443"
        "min" = "443"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "80"
        "min" = "80"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "2380"
        "min" = "2379"
      }

      protocol = "6"
      source   = "10.0.0.0/16"
    },
    {
      tcp_options {
        "max" = "5432"
        "min" = "5432"
      }

      protocol = "6"
      source   = "10.0.0.0/16"
    },
    {
      tcp_options {
        "max" = "7331"
        "min" = "7331"
      }

      protocol = "6"
      source   = "10.0.0.0/16"
    },
    {
      tcp_options {
        "max" = "9300"
        "min" = "9200"
      }

      protocol = "6"
      source   = "10.0.0.0/16"
    },
  ]
}

############################################
# Datasource
############################################
# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ad" {
  compartment_id = "${var.tenancy_ocid}"
}

data "template_file" "ad_names" {
  count    = "${length(data.oci_identity_availability_domains.ad.availability_domains)}"
  template = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[count.index], "name")}"
}

############################################
# Create Bastion Subnet
############################################
resource "oci_core_subnet" "bastion" {
  availability_domain = "${data.template_file.ad_names.*.rendered[length(data.template_file.ad_names.*.rendered) - 1]}"
  compartment_id      = "${var.compartment_ocid}"
  cidr_block          = "${cidrsubnet(oci_core_virtual_network.chef.cidr_block, 14 , 0)}"
  security_list_ids   = ["${oci_core_security_list.sl.id}"]
  vcn_id              = "${oci_core_virtual_network.chef.id}"
  route_table_id      = "${oci_core_route_table.public.id}"
  dns_label           = "bastion"
}

############################################
# Create chef Subnets
############################################
resource "oci_core_subnet" "chef" {
  count                      = "${length(data.template_file.ad_names.*.rendered)}"
  availability_domain        = "${data.template_file.ad_names.*.rendered[count.index]}"
  cidr_block                 = "${cidrsubnet(oci_core_virtual_network.chef.cidr_block, 8 , count.index + 1)}"
  security_list_ids          = ["${oci_core_security_list.sl.id}"]
  compartment_id             = "${var.compartment_ocid}"
  vcn_id                     = "${oci_core_virtual_network.chef.id}"
  route_table_id             = "${oci_core_route_table.private.id}"
  dns_label                  = "ad${count.index + 1}"
  prohibit_public_ip_on_vnic = true
}
