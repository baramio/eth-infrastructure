terraform {
  required_version = ">= 1.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    template = {
      source = "hashicorp/template"
      version = ">= 0.13"
    }
  }
}

variable "ssh_public_key" {}
variable "network" {}
variable "cf_email" {}
variable "cf_tunnel_token" {}
variable "cf_zoneid" {}
variable "cf_acctid" {}
variable "ec1_name" {}
variable "ec2_name" {}
variable "region1" {}
variable "region2" {}
variable "instance_size_1" {}
variable "instance_size_2" {}
variable "cf_tunnel1_id" {}
variable "cf_tunnel1_name" {}
variable "cf_tunnel1_token" {}
variable "ig1_private_ip" {}
variable "vpc1_uuid" {}
variable "cf_tunnel2_id" {}
variable "cf_tunnel2_name" {}
variable "cf_tunnel2_token" {}
variable "ig2_private_ip" {}
variable "vpc2_uuid" {}

provider "digitalocean" {}
provider "cloudflare" {
  email     = var.cf_email
  api_token = var.cf_tunnel_token
}

resource "digitalocean_droplet" "execution_client_1" {
  image      = "ubuntu-20-04-x64"
  name       = "${var.network}-${var.ec1_name}"
  region     = var.region1
  size       = var.instance_size_1
  tags       = ["geth"]
  monitoring = true
  vpc_uuid   = var.vpc1_uuid
  user_data  = templatefile("ec_setup.yaml", {
    ssh_public_key     = var.ssh_public_key,
    network            = var.network,
    account            = var.cf_acctid,
    tunnel_id          = var.cf_tunnel1_id,
    tunnel_name        = var.cf_tunnel1_name,
    secret             = var.cf_tunnel1_token,
    gateway_private_ip = var.ig1_private_ip,
    volume_name        = "${var.network}${var.ec1_name}vol"
  })
}

resource "digitalocean_volume" "volume1" {
  region                  = var.region1
  name                    = "${var.network}${var.ec1_name}vol"
  size                    = 200
  initial_filesystem_type = "ext4"
  description             = "volume for ${var.network}-${var.ec1_name}"
}

resource "digitalocean_volume_attachment" "vol_attach_1" {
  droplet_id = digitalocean_droplet.execution_client_1.id
  volume_id  = digitalocean_volume.volume1.id
}

resource "digitalocean_droplet" "execution_client_2" {
  image      = "ubuntu-20-04-x64"
  name       = "${var.network}-${var.ec2_name}"
  region     = var.region2
  size       = var.instance_size_2
  tags       = ["geth"]
  monitoring = true
  vpc_uuid   = var.vpc2_uuid
  user_data  = templatefile("ec_setup.yaml", {
    ssh_public_key     = var.ssh_public_key,
    network            = var.network,
    account            = var.cf_acctid,
    tunnel_id          = var.cf_tunnel2_id,
    tunnel_name        = var.cf_tunnel2_name,
    secret             = var.cf_tunnel2_token,
    gateway_private_ip = var.ig2_private_ip,
    volume_name        = "${var.network}${var.ec2_name}vol"
  })
}

resource "digitalocean_volume" "volume2" {
  region                  = var.region2
  name                    = "${var.network}${var.ec2_name}vol"
  size                    = 200
  initial_filesystem_type = "ext4"
  description             = "volume for ${var.network}-${var.ec2_name}"
}

resource "digitalocean_volume_attachment" "vol_attach_2" {
  droplet_id = digitalocean_droplet.execution_client_2.id
  volume_id  = digitalocean_volume.volume2.id
}

resource "cloudflare_load_balancer" "loadbalancer" {
  zone_id          = var.cf_zoneid
  name             = "${var.network}-ec.baramio-nodes.com"
  fallback_pool_id = cloudflare_load_balancer_pool.pool2.id
  default_pool_ids = [cloudflare_load_balancer_pool.pool1.id]
  description      = "load balancer"
  proxied          = true
}

resource "cloudflare_load_balancer_monitor" "http_monitor" {
  type           = "http"
  expected_codes = "200"
  method         = "GET"
  timeout        = 5
  path           = "/"
  interval       = 60
  retries        = 2
  description    = "http load balancer"
  header {
    header = "Content-Type"
    values = ["application/json"]
  }
}

resource "cloudflare_load_balancer_pool" "pool1" {
  name = "${var.network}-lb-pool-1"
  origins {
    name    = "${var.network}-ec-1"
    address = "${var.cf_tunnel1_id}.cfargotunnel.com"
    enabled = true
  }
  minimum_origins    = 1
  monitor            = cloudflare_load_balancer_monitor.http_monitor.id
  notification_email = "joseph@baramio.com"
}

resource "cloudflare_load_balancer_pool" "pool2" {
  name = "${var.network}-lb-pool-2"
  origins {
    name    = "${var.network}-ec-2"
    address = "${var.cf_tunnel2_id}.cfargotunnel.com"
    enabled = true
  }
  minimum_origins    = 1
  monitor            = cloudflare_load_balancer_monitor.http_monitor.id
  notification_email = "joseph@baramio.com"
}

resource "cloudflare_record" "rpc" {
  zone_id = var.cf_zoneid
  name    = "${var.network}-ec-rpc"
  value   = "${var.network}-ec.baramio-nodes.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "ws" {
  zone_id = var.cf_zoneid
  name    = "${var.network}-ec-ws"
  value   = "${var.network}-ec.baramio-nodes.com"
  type    = "CNAME"
  proxied = true
}