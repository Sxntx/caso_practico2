/*
Variables file 
This file contains all variables names to use in config files.

Added neccesary variables to run config properly.
*/
variable "resource_group_name" {
  default = "rg-createdbyTF"
}

variable "location_name" {
  default = "uksouth"
}

variable "network_name" {
  default = "vnet1"
}

variable "subnet_name" {
  default = "subnet1"
}
