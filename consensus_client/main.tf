terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 0.13"
    }
  }
}

variable "network" {}
variable "eth1_endpoint" {
  sensitive = true
}
variable "checkpoint_sync" {
  sensitive = true
}
provider "kubernetes" {
  config_path    = "baramio-kubeconfig.yaml"
}

resource "kubernetes_namespace" "consensus_client" {
  metadata {
    name = "cc"
  }
}

resource "kubernetes_stateful_set" "cc-node" {
  metadata {
    name = "cc"
    namespace = "cc"
    labels = {
      app = "cc-node"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cc-node"
      }
    }
    template {
      metadata {
        labels = {
          app = "cc-node"
        }
      }
      spec {
        container {
          image = "sigp/lighthouse:latest-modern"
          name  = "cc-node"
          port {
            container_port = 9000
            name = "peers"
          }
          port {
            container_port = 5052
            name = "http"
          }
          port {
            container_port = 5054
            name = "metrics"
          }
          args = [
            "lighthouse",
            "beacon",
            "--datadir",
            "/opt/cc/data",
            "--http",
            "--http-address",
            "0.0.0.0",
            "--network",
            var.network,
            "--metrics",
            "--metrics-address",
            "0.0.0.0",
            "--checkpoint-sync-url",
            var.checkpoint_sync
          ]
          volume_mount {
            name        = "cc-data"
            mount_path  = "/opt/cc/data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "cc-data"
        namespace = "cc"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "100Gi"
          }
        }
        storage_class_name = "do-block-storage"
      }
    }
    service_name = "cc-node"
  }
}

resource "kubernetes_service" "cc_http_service" {
  metadata {
    name = "cc-node"
    namespace = "cc"
    labels = {
      app = "cc-node"
    }
  }
  spec {
    selector = {
      app = "cc-node"
    }
    type = "ClusterIP"
    port {
      port = "5052"
      protocol = "TCP"
      target_port = "5052"
      name = "http"
    }
    port {
      port = "5054"
      protocol = "TCP"
      target_port = "5054"
      name = "metrics"
    }
  }
}

resource "kubernetes_service" "cc_peers_service" {
  metadata {
    name = "cc-node-peers"
    namespace = "cc"
    labels = {
      app = "cc-node"
    }
  }
  spec {
    selector = {
      app = "cc-node"
    }
    type = "NodePort"
    port {
      port = "9000"
      protocol = "TCP"
      target_port = "9000"
      name = "tcp"
      node_port = "30933"
    }
    port {
      port = "9000"
      protocol = "UDP"
      target_port = "9000"
      name = "udp"
      node_port = "30933"
    }
  }
}
