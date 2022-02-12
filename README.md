# eth-nodes-ocd
ethereum ecosystem-related nodes one-click-deployment repository.

Current deployments:
* consensus client
* execution client
* ssv

Currently built to deploy onto DigitalOcean only.

## Execution Client
Terraform scripts for provisioning and deployment of the execution client. 
High availability, multi-region setup.

## Consensus Client
Ansible playbook for provisioning & deployment of the consensus client.
Currently pulls in [eth-docker](https://github.com/eth-educators/eth-docker) for ease of setup.

## SSV
Ansible playbook for provisioning & deployment of the [SSV operator node](https://docs.ssv.network/operators/installation-operator-1)

