resource "oci_objectstorage_bucket" "chef" {
  compartment_id = "${var.compartment_ocid}"
  name           = "${var.os_chef_bucket_name}"
  namespace      = "${data.oci_objectstorage_namespace.os.namespace}"

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "oci_objectstorage_object" "chef_validation_key" {
  depends_on = ["data.oci_objectstorage_object.chef_org_short_name_pem"]
  bucket     = "${oci_objectstorage_bucket.chef.name}"
  content    = "${data.oci_objectstorage_object.chef_org_short_name_pem.content}"
  namespace  = "${data.oci_objectstorage_namespace.os.namespace}"
  object     = "${var.chef_org_short_name}-validator.pem"

  lifecycle {
    ignore_changes = ["content"]
  }
}

resource "oci_objectstorage_object" "chef_client_key" {
  depends_on = ["data.oci_objectstorage_object.chef_user_name_pem"]
  bucket     = "${oci_objectstorage_bucket.chef.name}"
  content    = "${data.oci_objectstorage_object.chef_user_name_pem.content}"
  namespace  = "${data.oci_objectstorage_namespace.os.namespace}"
  object     = "${var.chef_user_name}.pem"

  lifecycle {
    ignore_changes = ["content"]
  }
}

data "oci_objectstorage_namespace" "os" {}

resource "oci_objectstorage_preauthrequest" "upload" {
  access_type  = "AnyObjectWrite"
  bucket       = "${oci_objectstorage_bucket.chef.name}"
  name         = "upload"
  namespace    = "${data.oci_objectstorage_namespace.os.namespace}"
  time_expires = "${timeadd(timestamp(), "30m")}"

  lifecycle {
    ignore_changes = ["time_expires"]
  }
}

data "oci_objectstorage_object" "chef_user_name_pem" {
  depends_on = ["null_resource.chef_server_create_user_and_org"]
  bucket     = "${oci_objectstorage_bucket.chef.name}"
  namespace  = "${data.oci_objectstorage_namespace.os.namespace}"
  object     = "${var.chef_user_name}.pem"
}

data "oci_objectstorage_object" "chef_org_short_name_pem" {
  depends_on = ["null_resource.chef_server_create_user_and_org"]
  bucket     = "${oci_objectstorage_bucket.chef.name}"
  namespace  = "${data.oci_objectstorage_namespace.os.namespace}"
  object     = "${var.chef_org_short_name}-validator.pem"
}
