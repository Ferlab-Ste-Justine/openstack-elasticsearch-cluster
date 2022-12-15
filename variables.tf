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

variable "masters_domains" {
  description = "Domains that should be added to the masters tls certificate. The first domain in the list will also be used in the internal cluster dns for service discovery"
  type = list(string)
}

variable "workers_domains" {
  description = "Worker domains that should be added to the certificate of the es workers"
  type = list(string)
  default = []
}

variable "nameserver_ips" {
  description = "Ips of the nameservers"
  type = list(string)
  default = []
}

variable "s3_endpoint" {
  description = "Endpoint used to connect to an s3-compatible store for backups"
  type = string
  default = ""
}

variable "s3_protocol" {
  description = "Protocol to use (http or https) when connecting to the s3 store for backups"
  type = string
  default = "https"
}

variable "s3_access_key" {
  description = "Endpoint used to connect to an s3-compatible store for backups"
  type = string
  default = ""
  sensitive = true
}

variable "s3_secret_key" {
  description = "Protocol to use (http or https) when connecting to the s3 store for backups"
  type = string
  default = ""
  sensitive = true
}

variable "ca" {
  description = "The ca that will sign the es certificates. Should have the following keys: key, key_algorithm, certificate"
  type = any
}

variable "organization" {
  description = "The es servers certificates' organization"
  type = string
  default = "Ferlab"
}

variable "certificate_validity_period" {
  description = "The es servers cluster's certificates' validity period in hours"
  type = number
  default = 100*365*24
}

variable "certificate_early_renewal_period" {
  description = "The es servers cluster's certificates' early renewal period in hours"
  type = number
  default = 365*24
}

variable "key_length" {
  description = "The key length of the certificates' private key"
  type = number
  default = 4096
}