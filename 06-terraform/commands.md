# Terraform Commands

## Install the AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws configure                           # access key, secret key, region, output format
aws sts get-caller-identity             # check which account and user you are using
aws s3 ls
```

Create a dedicated IAM user for the CLI rather than using the root account.

## Install Terraform (Ubuntu)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform
terraform --version
```

## Workflow

```bash
terraform init                          # download providers
terraform fmt                           # format the .tf files
terraform validate                      # check syntax and types
terraform plan                          # preview the changes
terraform apply                         # create/update; type "yes" to confirm
terraform destroy                       # delete everything this configuration created
```

## With a variables file (multi-ec2)

```bash
cd multi-ec2
terraform init
terraform validate
terraform plan -var-file=dev.tfvars -out=dev.tfplan
terraform apply dev.tfplan              # applies exactly what was planned
terraform output
terraform destroy -var-file=dev.tfvars
```

## Inspect expressions

```bash
terraform console -var-file=dev.tfvars
> local.instances
> var.configuration[0].application_name
```

## State

```bash
terraform state list                    # resources Terraform is tracking
terraform state show aws_instance.ec2["webserver-1"]
```

Never commit `terraform.tfstate` or `.terraform/`; they are in `.gitignore`.

Registry and provider docs: https://registry.terraform.io/
