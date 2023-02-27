data "template_file" "install" {
  template = "${file("./scripts/install.sh")}"
}

resource "oci_core_instance" "scanning_vm" {
  availability_domain = lookup(data.oci_identity_availability_domains.this.availability_domains[0], "name")
  compartment_id      = var.compartment_id
  display_name        = "scanning"
  shape               = var.scanning_shape
  freeform_tags = {
    Managed = var.tags
  }
  
  shape_config {
    baseline_ocpu_utilization = "BASELINE_1_1"
    memory_in_gbs     = var.scanning_shape_mem
    ocpus             = var.scanning_shape_ocpus
  }

  create_vnic_details {
    assign_private_dns_record = true
    subnet_id                 = oci_core_subnet.Public_Subnet_scanning.id
    display_name              = "scanning-VNIC"
    assign_public_ip          = true
    freeform_tags = {
      Managed = var.tags
    }
  }

  source_details {
    source_type = "image"
    source_id   = var.scanning_image_source_ocid
  }

  metadata = {
    user_data           = base64encode(data.template_file.install.rendered)
  }
}
