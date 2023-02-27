resource "oci_events_rule" "test_rule" {
  condition      = var.event_condition
  compartment_id = var.compartment_id
  display_name   = var.rule_display_name
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
