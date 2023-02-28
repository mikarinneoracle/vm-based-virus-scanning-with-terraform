data "oci_core_services" "scanning_services" {
}

resource "oci_core_vcn" "scanning_vcn" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "scanning-VCN"
  dns_label      = "scanning"
  freeform_tags = {
    Managed = var.tags
  }
}

resource "oci_core_route_table" "scanning_private_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.scanning_vcn.id
  display_name   = "Route Table for Scanning Private Subnet"
  freeform_tags = {
    Managed = var.tags
  }

  route_rules {
    network_entity_id = oci_core_nat_gateway.scanning_nat_gw.id
    description       = "Route rules for Scanning NAT Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.scanning_service_gateway.id
    description       = "OCI Services via Service Gateway"
    destination       = var.services_network
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_nat_gateway" "scanning_nat_gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.scanning_vcn.id
  block_traffic  = false
  display_name   = "Scanning NAT Gateway"
  freeform_tags = {
    Managed = var.tags
  }
}

resource "oci_core_subnet" "Private_Subnet_scanning" {
  vcn_id              = oci_core_vcn.scanning_vcn.id
  dns_label           = "scanning"
  cidr_block          = "10.0.1.0/24"
  compartment_id      = var.compartment_id
  display_name        = "Scanning Private Subnet"
  freeform_tags       = {
    Managed = var.tags
  }
  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.scanning_private_rt.id
}

resource "oci_core_service_gateway" "scanning_service_gateway" {
  compartment_id = var.compartment_id
  services {
    service_id = data.oci_core_services.scanning_services.services.0.id
  }
  vcn_id       = oci_core_vcn.scanning_vcn.id
  display_name = "scanning Service Gateway"
  freeform_tags = {
    Managed = var.tags
  }
}
