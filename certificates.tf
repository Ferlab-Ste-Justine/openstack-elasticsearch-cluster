resource "tls_private_key" "masters_key" {
  algorithm   = "RSA"
  rsa_bits = var.key_length
}

resource "tls_cert_request" "masters_request" {
  key_algorithm   = tls_private_key.masters_key.algorithm
  private_key_pem = tls_private_key.masters_key.private_key_pem

  subject {
    common_name  = "masters"
    organization = var.organization
  }

  ip_addresses = concat(
    ["127.0.0.1"],
    [for idx in range(var.masters_count) : openstack_networking_port_v2.masters[idx].all_fixed_ips.0]
  )
  dns_names = concat(
    var.masters_domains,
    [for idx in range(var.masters_count) : "${local.master_base_name}-${idx + 1}"]
  )
}

resource "tls_locally_signed_cert" "masters_certificate" {
  cert_request_pem   = tls_cert_request.masters_request.cert_request_pem
  ca_key_algorithm   = var.ca.key_algorithm
  ca_private_key_pem = var.ca.key
  ca_cert_pem        = var.ca.certificate

  validity_period_hours = var.certificate_validity_period
  early_renewal_hours = var.certificate_early_renewal_period

  allowed_uses = [
    "server_auth",
    "client_auth",
  ]

  is_ca_certificate = false
}

resource "tls_private_key" "workers_key" {
  algorithm   = "RSA"
  rsa_bits = var.key_length
}

resource "tls_cert_request" "workers_request" {
  key_algorithm   = tls_private_key.workers_key.algorithm
  private_key_pem = tls_private_key.workers_key.private_key_pem

  subject {
    common_name  = "workers"
    organization = var.organization
  }

  ip_addresses = concat(
      ["127.0.0.1"],
      [for idx in range(var.workers_count) : openstack_networking_port_v2.workers[idx].all_fixed_ips.0]
  )
  dns_names = concat(
    var.workers_domains,
    [for idx in range(var.workers_count) : "${local.worker_base_name}-${idx + 1}"]
  )
}

resource "tls_locally_signed_cert" "workers_certificate" {
  cert_request_pem   = tls_cert_request.workers_request.cert_request_pem
  ca_key_algorithm   = var.ca.key_algorithm
  ca_private_key_pem = var.ca.key
  ca_cert_pem        = var.ca.certificate

  validity_period_hours = var.certificate_validity_period
  early_renewal_hours = var.certificate_early_renewal_period

  allowed_uses = [
    "server_auth",
    "client_auth",
  ]

  is_ca_certificate = false
}