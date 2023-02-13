## Execution Client
Terraform scripts for provisioning and deployment of the execution client. 
High availability setup with a hot standby node on a different region fronted by a load balancer that will 
auto-failover to the hot standby node when the primary node is down. 
Utilizes Cloudflare Load Balancer and Cloudflare Tunnels to achieve the multi-region load balancer setup

WIP

Resources:
* https://github.com/cloudflare/argo-tunnel-examples/tree/master/terraform-zerotrust-ssh-http-gcp
* https://github.com/eth-educators/eth-docker