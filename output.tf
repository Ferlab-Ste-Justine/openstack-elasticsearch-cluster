output masters {
  value = [
    for idx in range(var.masters_count) : {
      id = openstack_compute_instance_v2.masters[idx].id
      ip = openstack_networking_port_v2.masters[idx].all_fixed_ips.0
    }
  ]
}

output workers {
  value = [
    for idx in range(var.workers_count) : {
      id = openstack_compute_instance_v2.workers[idx].id
      ip = openstack_networking_port_v2.workers[idx].all_fixed_ips.0
    }
  ]
}