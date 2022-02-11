output "ec_1_ip_addr" {
  value = digitalocean_droplet.execution_client_1.ipv4_address
  description = "The public IP address of your droplet application."
}
output "tunnel1" {
  value = "${cloudflare_argo_tunnel.auto_tunnel1.id}.cfargotunnel.com"
  description = "The URL of the tunnel created for ec1"
}
#output "ec_2_ip_addr" {
#  value = digitalocean_droplet.execution_client_2.ipv4_address
#  description = "The public IP address of your droplet application."
#}