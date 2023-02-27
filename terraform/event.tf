resource "oci_events_rule" "test_rule" {
  display_name   = "Scanning"
  condition      = var.event_condition
  compartment_id = var.compartment_id
  is_enabled     = true
  description    = "Scanning Object Storage event"
  actions {
    actions {
        is_enabled  = true
        action_type = "FAAS"
        function_id = var.function_id
    }
  }
  freeform_tags = {
    Managed = var.tags
  }
}
