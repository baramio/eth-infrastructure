## Consensus Client
Terraform script for provisioning a consensus client node onto Kubernetes.
Will also expose the HTTP API port and assign a proxied domain with Cloudflare.

requirements: 
* terraform.tfvars: with the variables populated
* baramio-kubeconfig.yaml: kubernetes config file with access info - 
used to apply changes to the designated k8s cluster.

```commandline
terraform init
terraform plan
terraform apply
```

Upcoming: high availability, multi-region setup