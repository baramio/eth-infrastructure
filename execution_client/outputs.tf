output "ec_1_ip_addr" {
  value = digitalocean_droplet.execution_client_1.ipv4_address
  description = "The public IP address of your droplet application."
}
output "ec_2_ip_addr" {
  value = digitalocean_droplet.execution_client_2.ipv4_address
  description = "The public IP address of your droplet application."
}