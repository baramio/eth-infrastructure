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
  }
}

variable "ssh_public_key" {
  default     = 1
  description = "ssh public key to access droplets"
}
variable "network" {
  default     = "goerli"
  description = "network the geth node should be running on"
}

variable "ec1_name" {
  default     = "1-ec"
  description = "name of the first node"
}

variable "ec2_name" {
  default     = "2-ec"
  description = "name of the second node"
}

variable "cf_email" {
  default     = "me@baramio-nodes.com"
  description = "cloudflare email"
}

variable "cf_token" {
  default     = "wassup"
  description = "cloudflare token"
}

variable "cf_zoneid" {
  default     = "zone zone zone"
  description = "cloudflare zone id"
}

provider "digitalocean" {}
provider "cloudflare" {
  email   = var.cf_email
  api_token = var.cf_token
}

resource "digitalocean_droplet" "execution_client_1" {
  image     = "ubuntu-20-04-x64"
  name      = "${var.network}-${var.ec1_name}"
  region    = "nyc1"
  size      = "s-2vcpu-4gb"
  tags      = ["geth"]
  user_data = templatefile("ec_setup.yaml", {
    ssh_public_key = var.ssh_public_key,
    network = var.network ,
    cf_email = var.cf_email,
    cf_token = var.cf_token,
    ec_host = "${var.network}-${var.ec1_name}",
    ecws_host = "${var.network}-ws-${var.ec1_name}"
  })
}

resource "digitalocean_droplet" "execution_client_2" {
  image     = "ubuntu-20-04-x64"
  name      = "${var.network}-${var.ec2_name}"
  region    = "sfo3"
  size      = "s-2vcpu-4gb"
  tags      = ["geth"]
  user_data = templatefile("ec_setup.yaml", {
    ssh_public_key = var.ssh_public_key,
    network = var.network ,
    cf_email = var.cf_email,
    cf_token = var.cf_token,
    ec_host = "${var.network}-${var.ec2_name}",
    ecws_host = "${var.network}-ws-${var.ec2_name}"
  })
}

resource "cloudflare_load_balancer" "loadbalancer" {
  zone_id          = "${var.cf_zoneid}"
  name             = "${var.network}-ws-ec.baramio-nodes.com"
  fallback_pool_id = cloudflare_load_balancer_pool.pool2.id
  default_pool_ids = [cloudflare_load_balancer_pool.pool1.id]
  description      = "load balancer"
  proxied          = true
}

resource "cloudflare_load_balancer_pool" "pool1" {
  name = "${var.network}-lb-pool-1"
  origins {
    name    = "${var.network}-ws-ec-1"
    address = "${var.network}-ws-${var.ec1_name}.baramio-nodes.com"
    enabled = true
  }
  minimum_origins = 1
  notification_email = "joseph@baramio.com"
}

resource "cloudflare_load_balancer_pool" "pool2" {
  name = "${var.network}-lb-pool-2"
  origins {
    name    = "${var.network}-ws-ec-2"
    address = "${var.network}-ws-${var.ec2_name}.baramio-nodes.com"
    enabled = true
  }
  minimum_origins = 1
  notification_email = "joseph@baramio.com"
}