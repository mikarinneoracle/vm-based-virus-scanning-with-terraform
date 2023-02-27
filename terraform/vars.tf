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

variable "function_id" {
  type    = string
  ### Replace with your Scanning function OCID
  default = "ocid1.fnfunc.oc1.eu-amsterdam-1.aaaaaaaa4v4znguopj4vmr37pku6up7i6znbvkz7vqxctly7ampcx7wsk5oq"
}

variable "scanning_image_source_ocid" {
  type    = string
  ### Replace with your Scanning VM Image OCID
  default = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaaxski5mtcps44ilaajkvezlfmkzyepcrkc7m7oc3xg6xilrd76cfa"
}

variable "event_condition" {
  type    = string
  ### Replace with your Compartment OCID
  default = "{\"eventType\":[\"com.oraclecloud.objectstorage.updateobject\",\"com.oraclecloud.objectstorage.createobject\"],\"data\":{\"compartmentId\":[\"ocid1.compartment.oc1..aaaaaaaawccfklp2wj4c5ymigrkjfdhcbcm3u5ripl2whnznhmvgiqdatqgq\"],\"additionalDetails\":{\"bucketName\":[\"scanning\"]}}}"
}

variable "use_always_free" {
  ### Set to true if want to use always free VM (shapes may not be available)
  default = false
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
