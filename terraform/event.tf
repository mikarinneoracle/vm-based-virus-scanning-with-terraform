resource "oci_events_rule" "scan_rule" {
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

resource "oci_events_rule" "clean_rule" {
  display_name   = "Scanned-clean"
  condition      = var.clean_event_condition
  compartment_id = var.compartment_id
  is_enabled     = true
  description    = "After Scanning Object Storage event when upload was clean"
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

resource "oci_events_rule" "infected_rule" {
  display_name   = "Scanned-infected"
  condition      = var.infected_event_condition
  compartment_id = var.compartment_id
  is_enabled     = true
  description    = "After Scanning Object Storage event when upload was infected"
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
