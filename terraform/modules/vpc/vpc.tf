variable "name_prefix" {}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = var.name_prefix }
}

resource "aws_subnet" "public_az1" {
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = "10.0.1.0/24"
  tags              = { Name = "${var.name_prefix}-public_az1" }
  vpc_id            = aws_vpc.this.id
}

resource "aws_subnet" "public_az2" {
  availability_zone = "${data.aws_region.current.name}b"
  cidr_block        = "10.0.2.0/24"
  tags              = { Name = "${var.name_prefix}-public_az2" }
  vpc_id            = aws_vpc.this.id
}

resource "aws_subnet" "private_az1" {
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = "10.0.11.0/24"
  tags              = { Name = "${var.name_prefix}-private_az1" }
  vpc_id            = aws_vpc.this.id
}

resource "aws_subnet" "private_az2" {
  availability_zone = "${data.aws_region.current.name}b"
  cidr_block        = "10.0.12.0/24"
  tags              = { Name = "${var.name_prefix}-private_az2" }
  vpc_id            = aws_vpc.this.id
}

data "aws_region" "current" {}

resource "aws_db_subnet_group" "private" {
  name       = "${var.name_prefix}-private"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  tags       = { Name = "${var.name_prefix}-private" }
}

resource "aws_internet_gateway" "this" {
  tags   = { Name = var.name_prefix }
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_internet_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
  route_table_id         = aws_vpc.this.default_route_table_id
}

resource "aws_route_table_association" "public_az1" {
  route_table_id = aws_vpc.this.default_route_table_id
  subnet_id      = aws_subnet.public_az1.id
}

resource "aws_route_table_association" "public_az2" {
  route_table_id = aws_vpc.this.default_route_table_id
  subnet_id      = aws_subnet.public_az2.id
}

resource "aws_vpc_endpoint" "s3" {
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  tags         = { Name = "${var.name_prefix}-s3" }
  vpc_id       = aws_vpc.this.id
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  route_table_id  = aws_vpc.this.default_route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

output "vpc" {
  value = aws_vpc.this
}

output "public_subnets" {
  value = [
    aws_subnet.public_az1,
    aws_subnet.public_az2,
  ]
}

output "private_subnet_group" {
  value = aws_db_subnet_group.private
}
