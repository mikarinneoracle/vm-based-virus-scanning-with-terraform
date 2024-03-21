variable "region" {
  type    = string
  ### Replace with your Region if not AMS
  default = "eu-amsterdam-1"
}

variable "compartment_id" {
  type    = string
  ### Replace with your Compartment OCID
  default = "ocid1.compartment.oc1..aaaaaaaa...."
}

variable "function_id" {
  type    = string
  ### Replace with your Scanning function OCID
  default = "ocid1.fnfunc.oc1.eu-amsterdam-1.aaaaaaaa4...."
}

variable "event_condition" {
  type    = string
  ### Replace with your Compartment OCID
  default = "{\"eventType\":[\"com.oraclecloud.objectstorage.updateobject\",\"com.oraclecloud.objectstorage.createobject\"],\"data\":{\"compartmentId\":[\"ocid1.compartment.oc1..aaaaaaaa....\"],\"additionalDetails\":{\"bucketName\":[\"scanning\"]}}}"
}

variable "clean_event_condition" {
  type    = string
  ### Replace with your Compartment OCID
  default = "{\"eventType\":[\"com.oraclecloud.objectstorage.updateobject\",\"com.oraclecloud.objectstorage.createobject\"],\"data\":{\"compartmentId\":[\"ocid1.compartment.oc1..aaaaaaaa...."],\"additionalDetails\":{\"bucketName\":[\"scanned\"]}}}"
}

variable "infected_event_condition" {
  type    = string
  ### Replace with your Compartment OCID
  default = "{\"eventType\":[\"com.oraclecloud.objectstorage.updateobject\",\"com.oraclecloud.objectstorage.createobject\"],\"data\":{\"compartmentId\":[\"ocid1.compartment.oc1..aaaaaaaa....\"],\"additionalDetails\":{\"bucketName\":[\"scanning-alert-report\"]}}}"
}

variable "tags" {
  type    = string
  default = "created by Terraform"
}
