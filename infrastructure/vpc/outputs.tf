output "public_subnets" {
  value = [for s in values(aws_subnet.public_subnets) : s.id]
}

output "private_subnets" {
  value = [for s in values(aws_subnet.private_subnets) : s.id]
}

output "vpc_id" {
  value = aws_vpc.main.id
}
