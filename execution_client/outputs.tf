output "ip_address" {
  value = digitalocean_droplet.execution_client_1.ipv4_address
  description = "The public IP address of your droplet application."
}