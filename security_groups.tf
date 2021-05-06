resource "openstack_networking_secgroup_v2" "es_master" {
  name                 = var.namespace == "" ? "es-master" : "es-master-${var.namespace}"
  description          = "Security group for es masters"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_v2" "es_worker" {
  name                 = var.namespace == "" ? "es-worker" : "es-worker-${var.namespace}"
  description          = "Security group for es wprlers"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_v2" "es_client" {
  name                 = var.namespace == "" ? "es-client" : "es-client-${var.namespace}"
  description          = "Security group for the clients connecting to the es cluster"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_v2" "es_bastion" {
  name                 = var.namespace == "" ? "es-bastion" : "es-bastion-${var.namespace}"
  description          = "Security group for the bastion connecting to es members"
  delete_default_rules = true
}

//Allow all outbound traffic from es members and bastion
resource "openstack_networking_secgroup_rule_v2" "es_master_outgoing_v4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "es_master_outgoing_v6" {
  direction         = "egress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "es_worker_outgoing_v4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

resource "openstack_networking_secgroup_rule_v2" "es_worker_outgoing_v6" {
  direction         = "egress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

resource "openstack_networking_secgroup_rule_v2" "es_bastion_outgoing_v4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.es_bastion.id
}

resource "openstack_networking_secgroup_rule_v2" "es_bastion_outgoing_v6" {
  direction         = "egress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.es_bastion.id
}

//Allow all traffic between of es masters and workers
resource "openstack_networking_secgroup_rule_v2" "es_master_to_master" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id  = openstack_networking_secgroup_v2.es_master.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "es_worker_to_master" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id  = openstack_networking_secgroup_v2.es_worker.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "es_master_to_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id  = openstack_networking_secgroup_v2.es_master.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

resource "openstack_networking_secgroup_rule_v2" "es_worker_to_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id  = openstack_networking_secgroup_v2.es_worker.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

//Allow port 22 traffic from the bastion
resource "openstack_networking_secgroup_rule_v2" "master_ssh_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id  = openstack_networking_secgroup_v2.es_bastion.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "worker_ssh_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id  = openstack_networking_secgroup_v2.es_bastion.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

//Allow port 22 traffic on the bastion
resource "openstack_networking_secgroup_rule_v2" "external_ssh_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.es_bastion.id
}

//Allow port 9200 traffic from the client
resource "openstack_networking_secgroup_rule_v2" "client_master_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9200
  port_range_max    = 9200
  remote_group_id  = openstack_networking_secgroup_v2.es_client.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "client_worker_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9200
  port_range_max    = 9200
  remote_group_id  = openstack_networking_secgroup_v2.es_client.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

//Allow clients and bastion to use icmp
resource "openstack_networking_secgroup_rule_v2" "client_icmp_master_access_v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_client.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "client_icmp_master_access_v6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_client.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "client_icmp_worker_access_v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_client.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

resource "openstack_networking_secgroup_rule_v2" "client_icmp_worker_access_v6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_client.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

resource "openstack_networking_secgroup_rule_v2" "bastion_icmp_master_access_v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_bastion.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "bastion_icmp_master_access_v6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_bastion.id
  security_group_id = openstack_networking_secgroup_v2.es_master.id
}

resource "openstack_networking_secgroup_rule_v2" "bastion_icmp_worker_access_v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_bastion.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

resource "openstack_networking_secgroup_rule_v2" "bastion_icmp_worker_access_v6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "icmp"
  remote_group_id  = openstack_networking_secgroup_v2.es_bastion.id
  security_group_id = openstack_networking_secgroup_v2.es_worker.id
}

resource "openstack_networking_secgroup_rule_v2" "bastion_external_icmp_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.es_bastion.id
}