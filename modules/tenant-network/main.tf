terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
}

data "openstack_networking_network_v2" "external_network" {
  name = var.external_network
}

locals {
  prefix = replace(var.name_prefix, ".", "_")
}

resource "openstack_networking_network_v2" "network" {
  name           = "${local.prefix}-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "subnet" {
  for_each        = var.subnets
  name            = "${local.prefix}-${each.key}-subnet"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = each.value
  ip_version      = 4
  dns_nameservers = var.dns_servers
}

resource "openstack_networking_router_v2" "router" {
  name                = "${local.prefix}-router"
  external_network_id = data.openstack_networking_network_v2.external_network.id
}

resource "openstack_networking_router_interface_v2" "subnet" {
  for_each  = openstack_networking_subnet_v2.subnet
  router_id = openstack_networking_router_v2.router.id
  subnet_id = each.value.id
}

resource "openstack_compute_keypair_v2" "keypair" {
  count      = var.create_keypair ? 1 : 0
  name       = "${local.prefix}-keypair"
  public_key = var.public_key
}
