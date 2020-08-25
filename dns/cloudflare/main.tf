locals {
  zone_id = "${lookup(data.cloudflare_zones.domain_zones.zones[0], "id")}"
}

variable "node_count" {}

variable "email" {}

variable "api_token" {}

variable "domain" {}

variable "subdomain" {}

variable "hostnames" {
  type = list
}

variable "hostnames_with_subdomain" {
  type = list
}

variable "public_ips" {
  type = list
}

provider "cloudflare" {
  email     = var.email
  api_token = var.api_token
}

data "cloudflare_zones" "domain_zones" {
  filter {
    name   = var.domain
    status = "active"
    paused = false
  }
}

resource "cloudflare_record" "hosts" {
  count = var.node_count

  zone_id = local.zone_id
  name    = element(var.hostnames_with_subdomain, count.index)
  value   = element(var.public_ips, count.index)
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "domain" {
  zone_id = local.zone_id
  name    = var.subdomain
  value   = element(var.public_ips, 0)
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "wildcard" {
  depends_on = [cloudflare_record.domain]

  zone_id = local.zone_id
  name    = "*.${var.subdomain}"
  value   = "${var.subdomain}.${var.domain}"
  type    = "CNAME"
  proxied = false
}

output "domains" {
  value = "${cloudflare_record.hosts.*.hostname}"
}
