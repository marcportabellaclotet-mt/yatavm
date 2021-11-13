module "vpc" {
  name   = "myvpc"
  source = "../"

  aws_region      = "us-west-2"
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.0.0/23", "10.0.2.0/23", "10.0.4.0/23"]
  public_subnets  = ["10.0.100.0/23", "10.0.102.0/23", "10.0.104.0/23"]

  public_inbound_acl_rules   = local.network_acls["public_inbound"]
  public_outbound_acl_rules  = local.network_acls["public_outbound"]
  private_inbound_acl_rules  = local.network_acls["private_inbound"]
  private_outbound_acl_rules = local.network_acls["private_outbound"]
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "nat_gateway_ips" {
  value = module.vpc.nat_gateway_ips
}