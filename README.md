# About

This terraform module provisions an elasticsearch 7 cluster on openstack.

The following security groups are provisioned with the cluster:
- **es-masters**: Internal security group allowing traffic between es members, 9200 tcp traffic from **es-client** and ssh traffic from the **es-bastion**
- **es-workers**: Internal security group allowing traffic between es members, 9200 tcp traffic from **es-client** and ssh traffic from the **es-bastion**
- **es-client**: Exported security group that should supplement other security groups on a vm and allows to send 9200 tcp traffic to any member of the es cluster.
- **es-bastion**: Exported standalone security group that opens up ssh traffic from the outside and allows to connect via ssh to any member of the es cluster.

# Limitations

## Security

Security is not enabled so the resulting cluster should not be used directly over an insecure network.

Any access over an insecure network should tls-termined and authenticated separately via a revese-proxy.

## Node Roles Topology Assumption

The module assumes that you will be working with dedicated masters nodes and dedicated worker nodes and supports that use-case.

## Prerequisites

The module has been developped with an Ubuntu 18.04 image. Any recent Debian-based distribution that uses systemd will probably work  well out of the box.

Furthermore, the module assumes that you have a dynamically configurable dns service that will be modified as part of the terraform execution.

# Usage

## Input Variables

- namespace: Namespace that will be prefixed to generated resources. Useful to avoid name clashes. Will not be used if omitted.
- image_id: ID of the OS image that will be used to provision the nodes.
- masters_flavor_id: VM sizing that will be used to provision the master nodes.
- workers_flavor_id: VM sizing that will be used to provision the worker nodes.
- masters_extra_security_group_ids: Additional security groups that will be associated with the master nodes.
- workers_extra_security_group_ids: Additional security groups that will be associated with the worker nodes.
- network_id: Id of the network the nodes will be attached to.
- keypair_name: Name of the ssh keypair that will be usable to ssh on any of the nodes.
- masters_count: Number of masters in the cluster.
- initial_masters_count: Value indicating the initial number of masters when the cluster was first bootstrapped (needed for es configurations). It should never be changed again after that (you can add masters by incrementing **masters_count** instead). If you change this value after the cluster has been provisioned, all the masters in your cluster will be destroyed and reprovisioned so don't do it.
- workers_count: Number of data nodes in the cluster.
- domain: Domain that needs to resolve to the ips of your master nodes.
- nameserver_ips: Ips of nameservers that will be added to the list of nameservers used by the nodes in the cluster.

## Output Variables

- **masters**: List of dedicated master nodes, each which is has the **id** and **ip** key
- **workers**: List of dedicated data nodes, each which is has the **id** and **ip** key
- **groups**: Security groups (ie, resources of type openstack_networking_secgroup_v2) that can be used to provide nodes with additional access to the es cluster. It has the following 2 groups: bastion, client.

## Example

Here's an example of how this module would be used:

```
module "elasticsearch_cluster" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-elasticsearch-cluster.git"
  image_id = module.ubuntu_bionic_image.id
  masters_flavor_id = module.reference_infra.flavors.nano.id
  workers_flavor_id = module.reference_infra.flavors.micro.id
  network_id = module.reference_infra.networks.internal.id
  security_group_ids = [
    module.reference_infra.security_groups.default.id
  ]
  keypair_name = openstack_compute_keypair_v2.bastion_internal_keypair.name
  workers_count = 3
  domain = "masters.elasticsearch.mydomain"
  nameserver_ips = local.nameserver_ips
}

module "elasticsearch_internal_domain" {
  source = "git::https://github.com/Ferlab-Ste-Justine/openstack-zonefile.git"
  domain = "elasticsearch.mydomain"
  container = openstack_objectstorage_container_v1.dns.name
  dns_server_name = "my.dns.server."
  a_records = concat([
    for master in module.elasticsearch_cluster.masters: {
      prefix = "masters"
      ip = master.ip
    }
  ],
  [
    for worker in module.elasticsearch_cluster.workers: {
      prefix = "workers"
      ip = worker.ip
    } 
  ])
}
```