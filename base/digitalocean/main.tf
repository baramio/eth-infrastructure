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

variable "ssh_public_key" {}
variable "network" {}
variable "cf_email" {}
variable "cf_tunnel_token" {}
variable "cf_acctid" {}
variable "name1" {
  default     = "aeolus"
  description = "name of the first node"
}
variable "name2" {
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
variable "vpc_network_prefix1" {
  default     = "10.3.3.0/24"
  description = "vpc network prefix for vpc 1"
}
variable "vpc_network_prefix2" {
  default     = "10.3.4.0/24"
  description = "vpc network prefix for vpc 2"
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
  name       = "${var.network}-${var.name1}-${var.region1}-tunnel"
  secret     = random_id.tunnel_secret1.b64_std
}
# A Named Tunnel resource called zero_trust_ssh_http
resource "cloudflare_argo_tunnel" "auto_tunnel2" {
  account_id = var.cf_acctid
  name       = "${var.network}-${var.name2}-${var.region2}-tunnel"
  secret     = random_id.tunnel_secret2.b64_std
}

resource "digitalocean_vpc" "vpc1" {
  name     = "baramio-eth-${var.region1}-vpc"
  region   = var.region1
  ip_range = var.vpc_network_prefix1
}

resource "digitalocean_droplet" "internet_gateway1" {
  image      = "ubuntu-20-04-x64"
  name       = "baramio-eth-${var.region1}-vpc-ig"
  region     = var.region1
  size       = "s-1vcpu-1gb"
  tags       = ["internet_gateway"]
  monitoring = true
  vpc_uuid   = digitalocean_vpc.vpc1.id
  user_data  = templatefile("ig_setup.yaml", {
    ssh_public_key = var.ssh_public_key,
    vpc_network_prefix = var.vpc_network_prefix1,

  })
}

resource "digitalocean_vpc" "vpc2" {
  name     = "baramio-eth-${var.region2}-vpc"
  region   = var.region2
  ip_range = var.vpc_network_prefix2
}

resource "digitalocean_droplet" "internet_gateway2" {
  image      = "ubuntu-20-04-x64"
  name       = "baramio-eth-${var.region2}-vpc-ig"
  region     = var.region2
  size       = "s-1vcpu-1gb"
  tags       = ["internet_gateway"]
  monitoring = true
  vpc_uuid   = digitalocean_vpc.vpc2.id
  user_data  = templatefile("ig_setup.yaml", {
    ssh_public_key = var.ssh_public_key,
    vpc_network_prefix = var.vpc_network_prefix2,

  })
}
