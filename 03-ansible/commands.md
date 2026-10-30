# Ansible Commands

## Install (on the master)

```bash
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
ansible --version                       # also shows which ansible.cfg is in use
```

## SSH from master to workers

```bash
ssh-keygen                              # on the master; accept the defaults
cat ~/.ssh/id_rsa.pub                   # copy into ~/.ssh/authorized_keys on each worker
ssh <worker-private-ip>                 # check the connection
```

With a named key file instead of the default:

```bash
ssh -i ~/.ssh/<keyfile> <worker-private-ip>
```

## Static inventory

```bash
sudo mkdir -p /etc/ansible
sudo vi /etc/ansible/hosts
```

```ini
[servers]
<worker_hostname> ansible_host=<worker_private_ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/<keyfile>

[testgroup]
kslave1 ansible_host=172.31.3.159

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

Or set defaults once in `ansible.cfg`:

```ini
[defaults]
inventory = ./hosts
private_key_file = ~/.ssh/<keyfile>
remote_user = ubuntu
```

## Ad-hoc commands

```bash
ansible all -m ping
ansible all -a "free -m"
ansible all -a "df -h"
ansible all -a "uptime"
ansible all -a "free -m" --private-key=~/.ssh/<keyfile>
```

## Playbooks

```bash
ansible-playbook playbooks/package-playbook.yaml --syntax-check
ansible-playbook playbooks/package-playbook.yaml
ansible-playbook playbooks/variable-useradd.yaml --extra-vars "username=vir"
ansible-playbook playbooks/multi-playbook.yaml --extra-vars "username=vir"
```

## Roles

```bash
cd roles
ansible-galaxy init apache2             # creates tasks/, handlers/, vars/, defaults/, meta/ ...
ansible-galaxy init prerequisites
ansible-playbook stack.yaml
```

## Dynamic inventory (AWS)

```bash
ansible-galaxy collection install amazon.aws
pip install boto3 botocore              # AWS SDK the plugin needs
aws configure                           # access key, secret, region

ansible-inventory -i dynamic-inventory/aws_ec2.yaml --graph
ansible-playbook -i dynamic-inventory/aws_ec2.yaml dynamic-inventory/simple.yml
```

## AWS IAM user from a playbook

```bash
sudo snap install aws-cli --classic
aws configure
ansible-playbook playbooks/aws-iam-user.yaml
```

Module reference: https://docs.ansible.com/ansible/latest/collections/index.html
