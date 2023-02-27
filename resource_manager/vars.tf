variable "region" {
  type    = string
  ### Replace with your Region if not AMS
  default = "eu-amsterdam-1"
}

variable "availability_domain" {
  type    = string
  ### Replace with your Region AD if not AMS
  default = "eu-amsterdam-1-AD-1" 
}

variable "services_network" {
  type    = string
  ### Replace with your 'ams' Region key if not AMS
  default = "all-ams-services-in-oracle-services-network" 
}

variable "compartment_id" {
  type    = string
  ### Replace with your Compartment OCID
  default = "ocid1.compartment.oc1..aaaaaaaawccfklp2wj4c5ymigrkjfdhcbcm3u5ripl2whnznhmvgiqdatqgq"
}

variable "scanning_image_source_ocid" {
  type    = string
  ### Replace with your Scanning VM Image OCID
  default = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaaxski5mtcps44ilaajkvezlfmkzyepcrkc7m7oc3xg6xilrd76cfa"
}

variable "scanning_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "scanning_shape_mem" {
  type    = string
  default = "64"
}

variable "scanning_shape_ocpus" {
  type    = string
  default = "2"
}

variable "tags" {
  type    = string
  default = "created by Terraform"
}
