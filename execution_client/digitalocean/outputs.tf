output "ec_1_ip_addr" {
  value = digitalocean_droplet.execution_client_1.ipv4_address_private
  description = "The private IP address of your droplet application."
}

output "ec_2_ip_addr" {
  value = digitalocean_droplet.execution_client_2.ipv4_address_private
  description = "The private IP address of your droplet application."
}
