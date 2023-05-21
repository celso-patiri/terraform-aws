# Terraform Introduction

IaC to provision multiple VMs in AWS, setup ASG with Load Balancer to scale load across the cluster, and build simple infrastructure to run scalable, highly available microservices

---

- [Based on this awesome video](https://www.youtube.com/watch?v=6XSroskdCF0)
- Requires AWS account

## Notes

- [Terraform](#terraform)
- [Terraform Expressions](#terraform-expressions)
- [Terraform Variables](#terraform-variables)
- [AWS](#aws)
- [Virtual Private Cloud ](#vpc)
- [Auto Scaling Group](#asg)
- [Subnet IDs](#subnet-ids)
- [Elastic Load Balancer](#elastic-load-balancer)

## Terraform

| Command  | Desc                                                                                                                                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| init     | initialize a working directory containing Terraform configuration files. It scans the code for references to providers and downloads the required providers from the Terraform Registry.                      |
| plan     | used to create an execution plan. Terraform performs a refresh, unless explicitly disabled, and then determines what actions are necessary to achieve the desired state specified in the configuration files. |
| apply    | provision infrastructure based on the Terraform configuration                                                                                                                                                 |
| destroy  | destroy provisioned infrastructure                                                                                                                                                                            |
| validate | check if HCL syntax is valid on configuration files                                                                                                                                                           |

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
curl http://$(terraform output alb_dns_name | tr -d '"'):8080
> Hello, World!
```

### CIDR blocks

- Classless Inter-Domain Routing (CIDR) is a method for allocating IP addresses and routing Internet Protocol packets
- CIDR notation is a syntax for specifying IP addresses and their associated routing prefix
- CIDR notation is constructed from the IP address, a slash ('/') character, and the prefix length

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

### ASG

An Auto Scaling group contains a collection of EC2 instances that share similar characteristics and are treated as a logical grouping for the purposes of instance scaling and management

It takes care of provisioning a cluster of EC2 instances, and automatically replacing instances if they fail, as well as adjusting the size of the cluster according to load

This can be done in Terraform by specifying a `launch_configuration` resource, which defines the EC2 instance configuration, and an `auto_scaling_group` resource, which defines the group itself, and scaling policy

The `auto_scaling_group` resource uses the `launch_configuration` resource to create the EC2 instances

This can be an issue when updating `launch_configuration` since it is immutable (a fixed EC2 image is created based on the configuration)

In other scenarios of changes in immutable infrastructure, like modifying the `user_data` property and running the `apply` command, Terraform will destroy and provision a new instance with the new values

However, in the case of `auto_scaling_group`, it uses a reference to the original declared resource, and it can't delete the instance. Running `apply` after changes would return an error

This can be fixed using a lifecycle setting, which can control how the resource is created, updated or destroyed. Each terraform resource supports multiple lifecycle setting

The `create_before_destroy` setting will create a new resource before destroying the old one, and then destroy the old one after the new one has been created

The `auto_scaling_group` resource also defines the `load_balancers` attribute, which specifies the load balancer to use

### Subnet IDs

Another necessary attribute for the `auto_scaling_group` resource is the `vpc_zone_identifier`, which specifies the subnet IDs to use

Subnet IDs tells the ASG which VPC subnets to deploy the EC2 instances in.

Each subnet is in a different AWS availability zone, which ensures availability in case of a failure in one of the zones

This can be achieved using Terraform `Data Sources` to dynamically pull up list of Subnets in account

- Data sources are declared using the `data` block, and represent read-only information pulled from the provider
- It is a way to fetch information from the provider APIs and make it available to the Terraform configuration
- Each provider has its own set of data sources
- AWS has data sources for EC2, VPC, Subnets, user identity etc.

In the case of this repository:

- We use the `aws_vpc` data source, using the `default` VPC
- We use its the VPC's `id` in the `aws_subnet_ids` data source, which returns a list of subnet IDs in the VPC
- We extract the subnet ids from the `aws_subnet_ids` data source, and use it on the `aws_autoscaling_group` resource
- This instructs the ASG to deploy the EC2 instances in the subnets defined in the default VPC
- Without further configuration the ASG can be deployed, but each instance will have its own public IP address, which is not ideal
- To fix this, we can use a load balancer to distribute traffic across the instances

### Elastic Load Balancer

An Elastic Load Balancer (ELB) is a load balancing service provided by AWS

AWS provides three types of ELB:

- Application Load Balancer (ALB)
  - Best suited for load balancing of HTTP and HTTPS traffic
  - Operates at layer 7 (application layer) of the OSI model
  - Supports path-based routing
- Network Load Balancer (NLB)
  - Best suited for load balancing of TCP, UDP and TLS traffic
  - Can scale up and down in response to load faster than ALB
  - Designed to scale to handle millions of requests per second
  - Operates at layer 4 (transport layer) of the OSI model
- Classic Load Balancer (CLB)
  - Legacy ELB, predecessor to ALB and NLB
  - Far fewer features than ALB and NLB
  - Operates at both layer 4 and layer 7 of the OSI model
  - Should generally be avoided

Given that the simple web server in this repository only serves HTTP traffic, ALB will be the most suitable options

The ALB consists of:

- Listener

  - A process that listens on a specific port and protocol, checks for connection requests
  - It is configured with a protocol and port number for connections from clients to the load balancer
  - It checks for connection requests from clients, using the protocol and port number configured
  - It forwards requests to one or more target groups, based on the rules defined

- Listener Rule

  - A rule that defines how traffic should be routed to target groups based on the conditions defined
  - It takes requests that come to a listener, and send them to specific paths or hostnames

- Target Groups
  - A group of instances that should receive traffic from a particular listener
  - Also performs health checks on the instances, and only sends traffic to healthy instances

We can use the `aws_lb` resource in Terraform, and configure it to route traffic to the ASG

AWS load balancer are not a single server, but multiple server that can operate on separate subne4ts

AWS automatically adjusts the number of load bgalancer servers bade on the traffic, and manages fail over in case of failure, providing scalability and availability right of the gate

The next step is to create a listener for the load balancer using the `aws_lb_listener` resource

All AWS resources don't allow incoming and outgoing traffic by default. Thus we need to create a security group for the ALB

## Refs

- [AWS: Security best practices in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform docs: aws_instance provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [AWS: Elastic Load Balancing](https://aws.amazon.com/elasticloadbalancing/)
