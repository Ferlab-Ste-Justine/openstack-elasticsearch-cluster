locals {
  master_base_name = var.namespace != "" ? "es-master-${var.namespace}" : "es-master"
  worker_base_name = var.namespace != "" ? "es-worker-${var.namespace}" : "es-worker"
  cluster_name = var.namespace != "" ? "es-cluster-${var.namespace}" : "es-cluster"
}

data "template_cloudinit_config" "elasticsearch_master_config" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/cloud_config.yaml.tpl", 
      {
        nameserver_ips = var.nameserver_ips
        domain = var.masters_domains.0
        master = true
        initial_masters_count = var.initial_masters_count
        base_name = "${local.master_base_name}-"
        cluster_name = local.cluster_name
        s3_endpoint = var.s3_endpoint
        s3_protocol = var.s3_protocol
        s3_access_key = var.s3_access_key
        s3_secret_key = var.s3_secret_key
        server_key = tls_private_key.masters_key.private_key_pem
        server_certificate = tls_locally_signed_cert.masters_certificate.cert_pem
        ca_certificate = var.ca.certificate
      }
    )
  }
}

data "template_cloudinit_config" "elasticsearch_worker_config" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/cloud_config.yaml.tpl", 
      {
        nameserver_ips = var.nameserver_ips
        domain = var.masters_domains.0
        master = false
        initial_masters_count = var.initial_masters_count
        base_name = "${local.master_base_name}-"
        cluster_name = local.cluster_name
        s3_endpoint = var.s3_endpoint
        s3_protocol = var.s3_protocol
        s3_access_key = var.s3_access_key
        s3_secret_key = var.s3_secret_key
        server_key = tls_private_key.workers_key.private_key_pem
        server_certificate = tls_locally_signed_cert.workers_certificate.cert_pem
        ca_certificate = var.ca.certificate
      }
    )
  }
}

resource "openstack_networking_port_v2" "masters" {
  count          = 3
  name           = "${local.master_base_name}-${count.index + 1}"
  network_id     = var.network_id
  security_group_ids = concat(var.masters_extra_security_group_ids, [openstack_networking_secgroup_v2.es_master.id])
  admin_state_up = true
}

resource "openstack_networking_port_v2" "workers" {
  count          = 3
  name           = "${local.worker_base_name}-${count.index + 1}"
  network_id     = var.network_id
  security_group_ids = concat(var.workers_extra_security_group_ids, [openstack_networking_secgroup_v2.es_worker.id])
  admin_state_up = true
}

resource "openstack_compute_instance_v2" "masters" {
  count               = var.masters_count
  name                = "${local.master_base_name}-${count.index + 1}"
  image_id            = var.image_id
  flavor_id           = var.masters_flavor_id
  key_pair            = var.keypair_name
  user_data           = data.template_cloudinit_config.elasticsearch_master_config.rendered

  network {
    port = openstack_networking_port_v2.masters[count.index].id
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

resource "openstack_compute_instance_v2" "workers" {
  count               = var.workers_count
  name                = "${local.worker_base_name}-${count.index + 1}"
  image_id            = var.image_id
  flavor_id           = var.workers_flavor_id
  key_pair            = var.keypair_name
  user_data           = data.template_cloudinit_config.elasticsearch_worker_config.rendered

  network {
    port = openstack_networking_port_v2.workers[count.index].id
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}