output "ig_1_private_ip" {
  value = digitalocean_droplet.internet_gateway1.ipv4_address_private
}

output "vpc1_uuid" {
  value = digitalocean_vpc.vpc1.id
}

output "tunnel1_id" {
  value = cloudflare_argo_tunnel.auto_tunnel1.id
}

output "tunnel1_name" {
  value = cloudflare_argo_tunnel.auto_tunnel1.name
}

output "tunnel1_token" {
  value     = random_id.tunnel_secret1.b64_std
  sensitive = true
}

output "ig_2_private_ip" {
  value = digitalocean_droplet.internet_gateway2.ipv4_address_private
}

output "vpc2_uuid" {
  value = digitalocean_vpc.vpc2.id
}

output "tunnel2_id" {
  value = cloudflare_argo_tunnel.auto_tunnel2.id
}

output "tunnel2_name" {
  value = cloudflare_argo_tunnel.auto_tunnel2.name
}

output "tunnel2_token" {
  value     = random_id.tunnel_secret2.b64_std
  sensitive = true
}