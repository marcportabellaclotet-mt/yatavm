
################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  for_each = var.create_vpc ? { "${var.name}" : {} } : {}

  cidr_block = var.cidr
  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
    var.vpc_tags,
  )
}

################################################################################
# Private subnet
################################################################################

resource "aws_subnet" "private" {
  for_each = var.create_vpc ? local.private_subnets : {}

  vpc_id            = aws_vpc.this[var.name].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(
    {
      "Name" = format("%s-%s", each.value.az, each.value.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags,
    var.private_subnet_tags,
  )
}

################################################################################
# Public subnet
################################################################################

resource "aws_subnet" "public" {
  for_each = var.create_vpc ? local.public_subnets : {}

  vpc_id            = aws_vpc.this[var.name].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(
    {
      "Name" = format("%s-%s", each.value.az, each.value.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags,
    var.public_subnet_tags,
  )
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  for_each = var.create_vpc ? { "${var.name}" : {} } : {}
  vpc_id   = aws_vpc.this[var.name].id

  tags = merge(
    {
      "Name" = format("%s", var.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags,
    var.igw_tags,
  )
}

output "subnet" {
  value = local.public_subnets
}

################################################################################
# Publiс routes
################################################################################

resource "aws_route_table" "public" {
  for_each = var.create_vpc ? { "${var.name}" : {} } : {}

  vpc_id = aws_vpc.this[var.name].id

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}", var.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags,
    var.public_route_table_tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  for_each = var.create_vpc ? aws_route_table.public : {}

  route_table_id         = aws_route_table.public[var.name].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[var.name].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  for_each = var.create_vpc ? local.public_subnets : {}
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[var.name].id
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "nat" {
  for_each = (var.create_vpc && ! var.shared_nat_gateway) ? local.private_subnets : {}

  vpc = true

  tags = merge(
    {
      "Name" = format("nat-%s-${var.private_subnet_suffix}-%s", var.name, each.value.az)
      "VPC"  = format("%s", var.name)
    },
    var.tags
  )
}

resource "aws_nat_gateway" "nat" {
  for_each = (var.create_vpc && ! var.shared_nat_gateway ) ? local.public_subnets : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}-%s", var.name, each.value.az)
      "VPC"  = format("%s", var.name)
    },
    var.tags
  )
  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "single_nat" {
  for_each = (var.create_vpc && var.shared_nat_gateway) ? { "${var.name}" : {} } : {}

  vpc = true

  tags = merge(
    {
      "Name" = format("nat-%s-${var.private_subnet_suffix}", var.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags
  )
}

resource "aws_nat_gateway" "single_nat" {
  for_each = (var.create_vpc && var.shared_nat_gateway ) ? { "${var.name}" : {} } : {}

  allocation_id = aws_eip.single_nat[each.key].id
  subnet_id     = tolist([for subnet in aws_subnet.public : subnet.id])[0]
  tags = merge(
    {
      "Name" = format("%s-${var.private_subnet_suffix}", var.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags
  )
  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Private routes
################################################################################

resource "aws_route_table" "private" {
  for_each = var.create_vpc ? local.private_subnets : {}

  vpc_id = aws_vpc.this[var.name].id

  tags = merge(
    {
      "Name" = format("%s-${var.private_subnet_suffix}-%s", var.name, each.value.az)
      "VPC"  = format("%s", var.name)
      "AZ"   = format("%s", each.value.az)
    },
    var.tags,
    var.private_route_table_tags,
  )
}

resource "aws_route" "private_nat_gateway" {
  for_each =  (var.create_vpc && ! var.shared_nat_gateway) ? aws_route_table.private : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "single_private_nat_gateway" {
  for_each =  (var.create_vpc && var.shared_nat_gateway) ? aws_route_table.private : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = tolist([for ng in aws_nat_gateway.single_nat : ng.id])[0]

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  for_each = var.create_vpc ? local.private_subnets : {}
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

################################################################################
# Public Network ACLs
################################################################################

resource "aws_network_acl" "public" {
  for_each = (var.create_vpc && var.create_acl_rules) ? { "${var.name}" : {} } : {}

  vpc_id     = aws_vpc.this[var.name].id
  subnet_ids = tolist([for subnet in aws_subnet.public : subnet.id])
  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}", var.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags,
    var.public_acl_tags,
  )
}

resource "aws_network_acl_rule" "public_ingress" {
  for_each = var.public_inbound_acl_rules

  network_acl_id  = aws_network_acl.public[var.name].id
  rule_number     = each.key
  egress          = false
  protocol        = each.value.protocol
  rule_action     = each.value.rule_action
  cidr_block      = lookup(each.value, "cidr_block", null)      #tfsec:ignore:aws-vpc-no-excessive-port-access
  ipv6_cidr_block = lookup(each.value, "ipv6_cidr_block", null) #tfsec:ignore:aws-vpc-no-excessive-port-access
}

resource "aws_network_acl_rule" "public_egress" {
  for_each = var.public_outbound_acl_rules

  network_acl_id  = aws_network_acl.public[var.name].id
  rule_number     = each.key
  egress          = true
  protocol        = each.value.protocol
  rule_action     = each.value.rule_action
  cidr_block      = lookup(each.value, "cidr_block", null)      #tfsec:ignore:aws-vpc-no-excessive-port-access
  ipv6_cidr_block = lookup(each.value, "ipv6_cidr_block", null) #tfsec:ignore:aws-vpc-no-excessive-port-access
}


################################################################################
# Private Network ACLs
################################################################################

resource "aws_network_acl" "private" {
  for_each = (var.create_vpc && var.create_acl_rules) ? { "${var.name}" : {} } : {}

  vpc_id     = aws_vpc.this[var.name].id
  subnet_ids = tolist([for subnet in aws_subnet.private : subnet.id])
  tags = merge(
    {
      "Name" = format("%s-${var.private_subnet_suffix}", var.name)
      "VPC"  = format("%s", var.name)
    },
    var.tags,
    var.private_acl_tags,
  )
}

resource "aws_network_acl_rule" "private_ingress" {
  for_each = var.private_inbound_acl_rules

  network_acl_id  = aws_network_acl.private[var.name].id
  rule_number     = each.key
  egress          = false
  protocol        = each.value.protocol
  rule_action     = each.value.rule_action
  cidr_block      = lookup(each.value, "cidr_block", null)      #tfsec:ignore:aws-vpc-no-excessive-port-access
  ipv6_cidr_block = lookup(each.value, "ipv6_cidr_block", null) #tfsec:ignore:aws-vpc-no-excessive-port-access
}

resource "aws_network_acl_rule" "private_egress" {
  for_each = var.private_outbound_acl_rules

  network_acl_id  = aws_network_acl.private[var.name].id
  rule_number     = each.key
  egress          = true
  protocol        = each.value.protocol
  rule_action     = each.value.rule_action
  cidr_block      = lookup(each.value, "cidr_block", null)      #tfsec:ignore:aws-vpc-no-excessive-port-access
  ipv6_cidr_block = lookup(each.value, "ipv6_cidr_block", null) #tfsec:ignore:aws-vpc-no-excessive-port-access
}
