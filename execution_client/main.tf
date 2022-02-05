terraform {
  required_version = ">= 1.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
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
  default     = "1-ec.baramio-nodes.com"
  description = "name of the first node"
}

variable "ec2_name" {
  default     = "2-ec.baramio-nodes.com"
  description = "name of the second node"
}
provider "digitalocean" {}

resource "digitalocean_droplet" "execution_client_1" {
  image     = "ubuntu-20-04-x64"
  name      = "${var.network}-${var.ec1_name}"
  region    = "nyc1"
  size      = "s-2vcpu-4gb"
  tags      = ["geth"]
  user_data = templatefile("ec_setup.yaml", { ssh_public_key = var.ssh_public_key, network = var.network })
}

resource "digitalocean_droplet" "execution_client_2" {
  image     = "ubuntu-20-04-x64"
  name      = "${var.network}-${var.ec2_name}"
  region    = "sfo3"
  size      = "s-2vcpu-4gb"
  tags      = ["geth"]
  user_data = templatefile("ec_setup.yaml", { ssh_public_key = var.ssh_public_key, network = var.network })
}
