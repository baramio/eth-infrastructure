
variable "cf_email" {}
variable "cf_tunnel_token" {
  sensitive = true
}
variable "cf_acctid" {}
variable "cf_zoneid" {}


provider "cloudflare" {
  email   = var.cf_email
  api_token = var.cf_tunnel_token
}
provider "random" {}


# setup HTTPS connection to the API/GUI using Cloudflare Tunnel and exposing it to a specified baramio-nodes domain
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

resource "cloudflare_argo_tunnel" "tunnel" {
  account_id = var.cf_acctid
  name       = "${var.network}-cc-tunnel"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_record" "record" {
  zone_id = var.cf_zoneid
  name    = "cc-${var.network}"
  value   = "${cloudflare_argo_tunnel.tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "kubernetes_secret" "cloudflared-creds" {
  metadata {
    name      = "cc-creds"
    namespace = "cc"
  }
  data = {
    "cert.json" = <<EOF
{
    "AccountTag"   : "${var.cf_acctid}",
    "TunnelID"     : "${cloudflare_argo_tunnel.tunnel.id}",
    "TunnelName"   : "${cloudflare_argo_tunnel.tunnel.name}",
    "TunnelSecret" : "${random_id.tunnel_secret.b64_std}"
}
    EOF
  }
}

resource "kubernetes_config_map" "cloudflared-config" {
  metadata {
    name      = "cloudflared-config"
    namespace = "cc"
  }
  data = {
    "config.yaml" = <<EOF
tunnel: ${cloudflare_argo_tunnel.tunnel.id}
credentials-file: /etc/cloudflared/creds/cert.json
metrics: 0.0.0.0:2000
no-autoupdate: true

ingress:
  # route API requests to 5052
  - hostname: "${var.network}-cc.baramio-nodes.com"
    service: http://cc-node:5052
  # everything else is invalid
  - service: http_status:404
    EOF
  }
}

resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name = "cloudflared"
    namespace = "cc"
    labels = {
      app = "cloudflared"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cloudflared"
      }
    }
    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }
      spec {
        container {
          image = "cloudflare/cloudflared:2022.2.0"
          name  = "cloudflared"
          args  = ["tunnel", "--config", "/etc/cloudflared/config.yaml",  "run"]
          volume_mount {
            name       = "cloudflared-config"
            mount_path = "/etc/cloudflared"
            read_only  = true
          }
          volume_mount {
            name       = "cloudflared-creds"
            mount_path = "/etc/cloudflared/creds"
            read_only  = true
          }
          liveness_probe {
            http_get {
              path = "/ready"
              port = 2000
            }
            failure_threshold     = 1
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
        volume {
          name = "cloudflared-creds"
          secret {
            secret_name = "cloudflared-creds"
          }
        }
        volume {
          name = "cloudflared-config"
          config_map {
            name = "cloudflared-config"
          }
        }
      }
    }
  }
}
