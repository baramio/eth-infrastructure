terraform {
  required_version = ">= 1.0.0"

  required_providers {
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
variable "region1" {
  default     = "tiernet-bend-or"
  description = "region 1"
}

#variable "name2" {
#  default     = "boreas"
#  description = "name of the second node"
#}
#variable "region2" {
#  default     = "sfo3"
#  description = "region 2"
#}

provider "cloudflare" {
  email   = var.cf_email
  api_token = var.cf_tunnel_token
}
provider "random" {}

# The random_id resource is used to generate a 35 character secret for the tunnel
resource "random_id" "tunnel_secret1" {
  byte_length = 35
}
# A Named Tunnel resource called zero_trust_ssh_http
resource "cloudflare_argo_tunnel" "auto_tunnel1" {
  account_id = var.cf_acctid
  name       = "${var.network}-${var.name1}-${var.region1}-tunnel"
  secret     = random_id.tunnel_secret1.b64_std
}

## The random_id resource is used to generate a 35 character secret for the tunnel
#resource "random_id" "tunnel_secret2" {
#  byte_length = 35
#}
## A Named Tunnel resource called zero_trust_ssh_http
#resource "cloudflare_argo_tunnel" "auto_tunnel2" {
#  account_id = var.cf_acctid
#  name       = "${var.network}-${var.name2}-${var.region2}-tunnel"
#  secret     = random_id.tunnel_secret2.b64_std
#}
