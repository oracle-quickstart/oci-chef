resource "random_id" "ssh_keys_bucket_name" {
  byte_length = 8
  prefix      = "ssh-keys-"
}

resource "random_id" "chef_bucket_name" {
  byte_length = 8
  prefix      = "chef-"
}

resource "oci_objectstorage_bucket" "ssh_keys" {
  compartment_id = "${var.compartment_ocid}"
  name           = "${coalesce(var.os_ssk_key_bucket_name,random_id.ssh_keys_bucket_name.hex)}"
  namespace      = "${data.oci_objectstorage_namespace.os.namespace}"

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "oci_objectstorage_object" "bastion_private_key" {
  bucket    = "${oci_objectstorage_bucket.ssh_keys.name}"
  content   = "${tls_private_key.ssh_key.private_key_pem}"
  namespace = "${data.oci_objectstorage_namespace.os.namespace}"
  object    = "bastion_private_key.pem"
}

resource "oci_objectstorage_object" "bastion_authorized_keys" {
  bucket    = "${oci_objectstorage_bucket.ssh_keys.name}"
  content   = "${tls_private_key.ssh_key.public_key_openssh}"
  namespace = "${data.oci_objectstorage_namespace.os.namespace}"
  object    = "bastion_authorized_keys.pem"
}

resource "oci_objectstorage_object" "ssh_private_key" {
  bucket    = "${oci_objectstorage_bucket.ssh_keys.name}"
  content   = "${tls_private_key.ssh_key.private_key_pem}"
  namespace = "${data.oci_objectstorage_namespace.os.namespace}"
  object    = "ssh_private_key.pem"
}

resource "oci_objectstorage_object" "ssh_authorized_keys" {
  bucket    = "${oci_objectstorage_bucket.ssh_keys.name}"
  content   = "${tls_private_key.ssh_key.public_key_openssh}"
  namespace = "${data.oci_objectstorage_namespace.os.namespace}"
  object    = "ssh_authorized_keys.pem"
}

data "oci_objectstorage_namespace" "os" {}
