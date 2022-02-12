## Consensus Client
Ansible playbook for provisioning & deployment of the consensus client.
Currently pulls in [eth-docker](https://github.com/eth-educators/eth-docker) for ease of setup.


provision instance & setup:
```commandline
ansible-playbook -i inventory.yml provision.yml --ask-become-pass --ask-vault-pass --extra-vars 'cc_host={MY_DOMAIN}' 
```
install consensus client:
```commandline
ansible-playbook -i inventory.yml install_and_configure.yml --ask-vault-pass --extra-vars "cc_host={MY_DOMAIN}"
```
note - if the provisioned instance has never been ssh'd into before, you will need to add this flag
`--ssh-common-args='-o StrictHostKeyChecking=no'` to the install playbook. First time only.

ISSUES: 
* creating a floating IP and adding the DNS record in Cloudflare in the provisioning ansible playbook 
is a redundant and unnecessary step - eth-docker already budnles in cloudflare-ddns container with traefik which 
handles this for you.
* inventory.yml needs to be manually updated before running
* it's two click deploy right now! Actually it's more because of `--ask-vault-pass`

PLANNED: 
* refactor ansible playbook to terraform
* remove dependency on eth-docker
* HA setup - cloudflare load balancer, cloudflare tunnels, redundant setup in different region

Resources:
* https://github.com/eth-educators/eth-docker