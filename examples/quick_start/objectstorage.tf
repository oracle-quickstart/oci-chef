resource "oci_objectstorage_bucket" "ssh_keys" {
  compartment_id = "${var.compartment_ocid}"
  name           = "${var.os_ssk_key_bucket_name}"
  namespace      = "${data.oci_objectstorage_namespace.os.namespace}"
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

data "oci_objectstorage_object" "chef_user_name_pem" {
  depends_on = ["module.chef"]
  bucket     = "${lookup(module.chef.os_chef, "bucket")}"
  namespace  = "${data.oci_objectstorage_namespace.os.namespace}"
  object     = "${lookup(module.chef.os_chef, "client_key")}"
}
