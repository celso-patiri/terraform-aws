# Terraform Introduction

- Provision several VMs in AWS
- Setup Load Balancer to scale load across the cluster
- Build simple infrastructure to run scalable, highly available microservices

## Steps

1. Set up AWS account
2. Install Terraform
3. Deploy a single server
4. Deploy a configurable web server
5. Deploy a cluster of web servers
6. Deploy a load balancer
7. Clean up

## AWS

The following environment variables are required for Terraform to manage AWS resources:

- export AWS_SECRET_ACCESS_KEY="..."
- export AWS_ACCESS_KEY_ID="..."

### Root User vs IAM User

- Root user has full access to all AWS services and resources in the account
- IAM user is an identity within your AWS account that has specific custom permissions (e.g. read-only access to S3 bucket)
- It is recommended to use IAM user instead of root user for day-to-day tasks
- Root user should only be used to create and manage IAM users

### VPC

- Virtual Private Cloud (VPC) is a virtual network dedicated to your AWS account
- It is logically isolated from other virtual networks in the AWS Cloud
- It has own virtual network and IP address range
- Default VPC by default is created for each AWS account

## Terraform

| Command | Desc                                                                                                                                                                                                          |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| init    | initialize a working directory containing Terraform configuration files. It scans the code for references to providers and downloads the required providers from the Terraform Registry.                      |
| plan    | used to create an execution plan. Terraform performs a refresh, unless explicitly disabled, and then determines what actions are necessary to achieve the desired state specified in the configuration files. |

For deploying a server, we could use a tool like HashiCorp Packer to build a custom EC2 image with all the required software installed. However

For this example though, we are using the simplest web server possible

```bash
echo "Hello World" > index.html

# Start the server
nohup busybox httpd -f -p 8080 &
```

We pass this script to the EC2 instance using the `user_data` attribute

The `user_data_replace_on_change = true` attribute ensures that the script is re-run if the `user_data` attribute is changed

Terraform default behavior is to modify behavior in-place, but since the `user_data` attribute is immutable and runs only at boot, Terraform will destroy and recreate the EC2 instance

AWS blocks all incoming and outgoing traffic by default. We need to create a security group to allow traffic to the EC2 instance using the `aws_security_group` resource

### Terraform Expressions

A Terraform expressions is something that produces a value

Terraform has many types of expressions, one such being the `reference` expression

When you pass a reference from one resource to another, you create implicit dependency

Terraform parses the implicit dependencies and builds a dependency graph, which is used to determine the correct order to create resources

This graph can be visualized using the `terraform graph` command (the output is in the DOT graph description language)

Leveraging the declarative syntax and the dependency graph, Terraform can create resources in parallel, speeding up the provisioning process

### Terraform Variables

Terraform variables allow you to parameterize your configuration

Variables can be defined in a `variables.tf` file

Variables can be specified at runtime using the `-var` and `-var-file` flags, Terraform also looks up variables in the environment with the `TF_VAR_` prefix

```bash
export TF_VAR_SERVER_PORT=8080
terraform apply -var="instance_type=t2.micro"
terraform apply -var-file="testing.tfvars"
```

Variables can have `type` constraints and `default` values, as well as a `validation` option

```hcl
validation {
  condition = var.server_port > 0 && var.server_port < 65536
  error_message = "The server port must be between 1 and 65536"
}
```

The `output` block prints out values at the end of the `terraform apply` command,

- The `depends_on` attribute can be used to specify explicit dependencies, a
- The `value` attribute specifies the value to be printed out, and can be any Terraform expression

The output can also be obtained using the `terraform output` command

```bash
terraform apply --auto-approve
# get value from terraform output
PUBLIC_IP=$(terraform output public_ip | tr -d '"')
curl http://"${PUBLIC_IP}":8080
```

### CIDR blocks

- Classless Inter-Domain Routing (CIDR) is a method for allocating IP addresses and routing Internet Protocol packets
- CIDR notation is a syntax for specifying IP addresses and their associated routing prefix
- CIDR notation is constructed from the IP address, a slash ('/') character, and the prefix length

## Refs

- [Security best practices in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform provider: aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)

```

```
