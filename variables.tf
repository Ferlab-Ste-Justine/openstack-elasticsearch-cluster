variable "namespace" {
  description = "Namespace to create the resources under"
  type = string
  default = ""
}

variable "image_id" {
    description = "ID of the vm image used to provision the node"
    type = string
}

variable "masters_flavor_id" {
  description = "ID of the VM flavor for the dedicated master nodes"
  type = string
}

variable "workers_flavor_id" {
  description = "ID of the VM flavor for the dedicated data nodes"
  type = string
}

variable "masters_extra_security_group_ids" {
  description = "Extra security groups for the masters"
  type = list(string)
  default = []
}

variable "workers_extra_security_group_ids" {
  description = "Extra security groups for the workers"
  type = list(string)
  default = []
}

variable "network_id" {
  description = "Id of the network the node will be attached to"
  type = string
}

variable "keypair_name" {
  description = "Name of the keypair that will be used to ssh to the node"
  type = string
}

variable "masters_count" {
  description = "Number of dedicated master nodes"
  type = number
  default = 3
}

variable "initial_masters_count" {
  description = "Initial number of dedicated master nodes when cluster is first bootstrapped"
  type = number
  default = 3
}

variable "workers_count" {
  description = "Number of dedicated data nodes"
  type = number
}

variable "domain" {
  description = "Domain that will be used in the local dns to expose all ips."
  type = string
}

variable "nameserver_ips" {
  description = "Ips of the nameservers"
  type = list(string)
  default = []
}