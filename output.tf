output "vpc_id" {
  description = "Returns VPC id"
  value       = aws_vpc.this["myvpc"].id
}

output "public_subnet_ids" {
  description = "Returns a list of public subnet ids"
  value       = tolist([for subnet in aws_subnet.public : subnet.id])
}

output "private_subnet_ids" {
  description = "Returns a list of private subnet ids"
  value       = tolist([for subnet in aws_subnet.private : subnet.id])
}

output "subnet_ids" {
  description = "Returns a list of all subnet ids"
  value       = concat(tolist([for subnet in aws_subnet.public : subnet.id]), tolist([for subnet in aws_subnet.private : subnet.id]))
}

output "nat_gateway_ips" {
  description = "Returns a list of nat gateways ips"
  value       = tolist([for nat in aws_eip.nat : nat.public_ip])
}
