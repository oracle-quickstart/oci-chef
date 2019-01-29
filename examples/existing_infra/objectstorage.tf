data "oci_objectstorage_namespace" "os" {}

data "oci_objectstorage_object" "chef_user_name_pem" {
  depends_on = ["module.chef"]
  bucket     = "${lookup(module.chef.os_chef, "bucket")}"
  namespace  = "${data.oci_objectstorage_namespace.os.namespace}"
  object     = "${lookup(module.chef.os_chef, "client_key")}"
}
