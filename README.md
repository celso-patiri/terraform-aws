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

## Refs

- [Security best practices in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform provider: aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
