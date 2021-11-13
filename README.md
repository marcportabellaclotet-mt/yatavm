## Table of Contents

- [Description](#description)
- [Motivation](#motivation)
- [Usage](#usage)
- [Subnets](#subnets)
- [Future Work](#future-work)
---

# Description

Yet Another Terraform AWS VPC module (yatavm).

## Motivation

- Most Terraform AWS modules use count to create resources. Sometimes this can cause issues and force to recreate resources when adding or changing vpc elements like nat gateways or routes.
- To avoid this, terraform can use for_each statement, which creates keys instead of indexes to define resources. 
- This terraform module only uses for_each statement to create conditional multielement resources.

## Usage

<details>
  <summary>VPC deployment example</summary>

```
module "vpc" {
  name   = "myvpc"
  source = "../"

  aws_region      = "us-west-2" # AWS region where the VPC will be deployed.
  cidr            = "10.0.0.0/16" # cidr of the vpc
  private_subnets = ["10.0.0.0/23", "10.0.2.0/23", "10.0.4.0/23"] # Private Subnets cidr
  public_subnets  = ["10.0.100.0/23", "10.0.102.0/23", "10.0.104.0/23"] # Public Subnets cidr

  # public_inbound_acl_rules   = local.network_acls["public_inbound"] # Optional
  # public_outbound_acl_rules  = local.network_acls["public_outbound"] # Optional
  # private_inbound_acl_rules  = local.network_acls["private_inbound"] # Optional
  # private_outbound_acl_rules = local.network_acls["private_outbound"] # Optional
}
```
</details>

## Subnets

- This module allows creating up to 1 subnet per each availability zone in the AWS region.
- For example, if you deploy a VPC in an AWS region which has 3 AZ, you can define a cidr list between 1 and 3 elements.
- The module automatically creates the subnets in different AZ and validates that the number of defined subnets are available in the AWS Region.

## Future Work

- Add variable to allow shared or single NAT per private subnet.
- Add extended functionality and option.
- README updates.
