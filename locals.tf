
locals {
  private_subnets = {
    for item in var.private_subnets :
    item => {
      "name" = var.private_subnet_name
      "cidr" = item
      "az"   = data.aws_availability_zones.this.names[index(var.private_subnets, item)]
    }
  }
  public_subnets = {
    for item in var.public_subnets :
    item => {
      "name" = var.public_subnet_name
      "cidr" = item
      "az"   = data.aws_availability_zones.this.names[index(var.public_subnets, item)]
    }
  }
}
