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
    random = {
      source = "hashicorp/random"
      version = ">= 0.13"
    }
    template = {
      source = "hashicorp/template"
      version = ">= 0.13"
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

variable "cf_email" {
  default     = "me@baramio-nodes.com"
  description = "cloudflare email"
}

variable "cf_tunnel_token" {
  default     = "hey"
  description = "cloudflare token for tunneling and load balancing"
}

variable "cf_zoneid" {
  default     = "zone zone zone"
  description = "cloudflare zone id"
}

variable "cf_acctid" {
  default     = "acct id"
  description = "cloudflare account id"
}

variable "ec1_name" {
  default     = "aeolus"
  description = "name of the first node"
}

variable "ec2_name" {
  default     = "boreas"
  description = "name of the second node"
}

variable "region1" {
  default     = "nyc1"
  description = "region 1"
}

variable "region2" {
  default     = "sfo3"
  description = "region 2"
}

variable "instance_size_1" {
  default     = "s-4vcpu-8gb"
  description = "instance size"
}

variable "instance_size_2" {
  default     = "s-4vcpu-8gb"
  description = "instance size"
}

provider "digitalocean" {}
provider "cloudflare" {
  email   = var.cf_email
  api_token = var.cf_tunnel_token
}
provider "random" {}

# The random_id resource is used to generate a 35 character secret for the tunnel
resource "random_id" "tunnel_secret1" {
  byte_length = 35
}
# The random_id resource is used to generate a 35 character secret for the tunnel
resource "random_id" "tunnel_secret2" {
  byte_length = 35
}
# A Named Tunnel resource called zero_trust_ssh_http
resource "cloudflare_argo_tunnel" "auto_tunnel1" {
  account_id = var.cf_acctid
  name       = "${var.network}-${var.ec1_name}-tunnel"
  secret     = random_id.tunnel_secret1.b64_std
}
# A Named Tunnel resource called zero_trust_ssh_http
resource "cloudflare_argo_tunnel" "auto_tunnel2" {
  account_id = var.cf_acctid
  name       = "${var.network}-${var.ec2_name}-tunnel"
  secret     = random_id.tunnel_secret2.b64_std
}

resource "digitalocean_droplet" "execution_client_1" {
  image      = "ubuntu-20-04-x64"
  name       = "${var.network}-${var.ec1_name}"
  region     = var.region1
  size       = var.instance_size_1
  tags       = ["geth"]
  monitoring = true
  user_data  = templatefile("ec_setup.yaml", {
    ssh_public_key = var.ssh_public_key,
    network        = var.network,
    account        = var.cf_acctid,
    tunnel_id      = cloudflare_argo_tunnel.auto_tunnel1.id,
    tunnel_name    = cloudflare_argo_tunnel.auto_tunnel1.name,
    secret         = random_id.tunnel_secret1.b64_std,
    volume_name    = "${var.network}_${var.ec1_name}_vol"
  })
}

resource "digitalocean_volume" "volume1" {
  region                  = var.region1
  name                    = "${var.network}_${var.ec1_name}_vol"
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
  user_data  = templatefile("ec_setup.yaml", {
    ssh_public_key = var.ssh_public_key,
    network        = var.network,
    account        = var.cf_acctid,
    tunnel_id      = cloudflare_argo_tunnel.auto_tunnel2.id,
    tunnel_name    = cloudflare_argo_tunnel.auto_tunnel2.name,
    secret         = random_id.tunnel_secret2.b64_std,
    volume_name    = "${var.network}_${var.ec2_name}_vol"
  })
}

resource "digitalocean_volume" "volume2" {
  region                  = var.region2
  name                    = "${var.network}_${var.ec2_name}_vol"
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
  type = "http"
  expected_codes = "200"
  method = "GET"
  timeout = 5
  path = "/"
  interval = 60
  retries = 2
  description = "http load balancer"
}

resource "cloudflare_load_balancer_pool" "pool1" {
  name = "${var.network}-lb-pool-1"
  origins {
    name    = "${var.network}-ec-1"
    address = "${cloudflare_argo_tunnel.auto_tunnel1.id}.cfargotunnel.com"
    enabled = true
  }
  minimum_origins = 1
  monitor = cloudflare_load_balancer_monitor.http_monitor.id
  notification_email = "joseph@baramio.com"
}

resource "cloudflare_load_balancer_pool" "pool2" {
  name = "${var.network}-lb-pool-2"
  origins {
    name    = "${var.network}-ec-2"
    address = "${cloudflare_argo_tunnel.auto_tunnel2.id}.cfargotunnel.com"
    enabled = true
  }
  minimum_origins = 1
  monitor = cloudflare_load_balancer_monitor.http_monitor.id
  notification_email = "joseph@baramio.com"
}