output "tunnel1_id" {
  value = cloudflare_argo_tunnel.auto_tunnel1.id
}

output "tunnel1_name" {
  value = cloudflare_argo_tunnel.auto_tunnel1.name
}

output "tunnel1_token" {
  value     = random_id.tunnel_secret1.b64_std
}


#output "tunnel2_id" {
#  value = cloudflare_argo_tunnel.auto_tunnel2.id
#}
#
#output "tunnel2_name" {
#  value = cloudflare_argo_tunnel.auto_tunnel2.name
#}
#
#output "tunnel2_token" {
#  value     = random_id.tunnel_secret2.b64_std
#}