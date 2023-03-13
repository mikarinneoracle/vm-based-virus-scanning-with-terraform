resource "oci_objectstorage_bucket" "scanning" {
  compartment_id        = var.compartment_id
  name                  = "scanning"
  namespace             = data.oci_objectstorage_namespace.user_namespace.namespace
  object_events_enabled = true
}

resource "oci_objectstorage_bucket" "scanned" {
  compartment_id = var.compartment_id
  name           = "scanned"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  object_events_enabled = true
}

resource "oci_objectstorage_bucket" "scanning_alert_report" {
  compartment_id = var.compartment_id
  name           = "scanning-alert-report"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  object_events_enabled = true
}

resource "oci_objectstorage_preauthrequest" "scanning_preauth" {
  access_type  = "ObjectWrite"
  bucket       = oci_objectstorage_bucket.scanning.name
  name         = "scanning_preauth"
  namespace    = data.oci_objectstorage_namespace.user_namespace.namespace
  object       = null
  object_name  = null
  time_expires = timeadd(timestamp(), "8765h")
}
