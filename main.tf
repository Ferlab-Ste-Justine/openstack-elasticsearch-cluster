data "template_cloudinit_config" "elasticsearch_master_config" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/cloud_config.yaml.tpl", 
      {
        nameserver_ips = var.nameserver_ips
        domain = var.domain
        master = true
        initial_masters_count = var.initial_masters_count
        base_name = var.namespace != "" ? "es-master-${var.namespace}-" : "es-master-"
        cluster_name = var.namespace != "" ? "es-cluster-${var.namespace}" : "es-cluster"
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
        domain = var.domain
        master = false
        initial_masters_count = var.initial_masters_count
        base_name = var.namespace != "" ? "es-master-${var.namespace}-" : "es-master-"
        cluster_name = var.namespace != "" ? "es-cluster-${var.namespace}" : "es-cluster"
      }
    )
  }
}

resource "openstack_networking_port_v2" "masters" {
  count          = 3
  name           = var.namespace != "" ? "es-master-${var.namespace}-${count.index + 1}" : "es-master-${count.index + 1}"
  network_id     = var.network_id
  security_group_ids = var.security_group_ids
  admin_state_up = true
}

resource "openstack_networking_port_v2" "workers" {
  count          = 3
  name           = var.namespace != "" ? "es-worker-${var.namespace}-${count.index + 1}" : "es-worker-${count.index + 1}"
  network_id     = var.network_id
  security_group_ids = var.security_group_ids
  admin_state_up = true
}

resource "openstack_compute_instance_v2" "masters" {
  count               = var.masters_count
  name                = var.namespace != "" ? "es-master-${var.namespace}-${count.index + 1}" : "es-master-${count.index + 1}"
  image_id            = var.image_id
  flavor_id           = var.masters_flavor_id
  key_pair            = var.keypair_name
  user_data           = data.template_cloudinit_config.elasticsearch_master_config.rendered

  network {
    port = openstack_networking_port_v2.masters[count.index].id
  }
}

resource "openstack_compute_instance_v2" "workers" {
  count               = var.workers_count
  name                = var.namespace != "" ? "es-worker-${var.namespace}-${count.index + 1}" : "es-worker-${count.index + 1}"
  image_id            = var.image_id
  flavor_id           = var.workers_flavor_id
  key_pair            = var.keypair_name
  user_data           = data.template_cloudinit_config.elasticsearch_worker_config.rendered

  network {
    port = openstack_networking_port_v2.workers[count.index].id
  }
}