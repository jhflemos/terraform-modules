resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = var.vpc_name
    },
    var.tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.environment}-vpc-igw"
    },
    var.tags
  )
}

resource "aws_subnet" "public_subnets" {
  for_each = { for idx, subnet in var.public_subnets : idx => subnet }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.environment}-public-${each.key}"
    },
    var.tags
  )
}

resource "aws_subnet" "private_subnets" {
  for_each = { for idx, subnet in var.private_subnets : idx => subnet }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.environment}-private-${each.key}"
    },
    var.tags
  )
}

resource "aws_eip" "nat_elastic_ips" {
  for_each = aws_subnet.public_subnets

  tags = merge(
    {
      Name = "${var.environment}-elastic-ip-${each.key}"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "nat_gateways" {
  for_each = aws_subnet.public_subnets

  allocation_id = aws_eip.nat_elastic_ips[each.key].id
  subnet_id     = each.value.id

  tags = merge(
    {
      Name = "${var.environment}-nat-gateway-${each.key}"
    },
    var.tags
  )
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    {
      Name = "${var.environment}-public-route-table"
    },
    var.tags
  )
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_tables" {
  for_each = aws_subnet.public_subnets # match NAT Gateway per AZ

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateways[each.key].id
  }

  tags = merge(
    {
      Name = "${var.environment}-private-route-table-${each.key}"
    },
    var.tags
  )
}

resource "aws_route_table_association" "private_route_table_association" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_tables[each.key].id
}
