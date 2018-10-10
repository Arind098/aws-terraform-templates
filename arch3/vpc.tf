resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr}"
  tags = "${merge(var.tags, map("Name", format("%s", var.name)))}"
}

resource "aws_internet_gateway" "igw" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${merge(var.tags, map("Name", format("%s-igw", var.name)))}"
}

##############################
# Public Subnet Configuration
##############################
resource "aws_subnet" "public-1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.public_subnets[0]}"
  availability_zone       = "${var.azs[0]}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_route_table" "public-rt-1" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "Route table - Public subnet 1"
  }
}

resource "aws_route" "public_route-1" {
  route_table_id         = "${aws_route_table.public-rt-1.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "public-rt-asoc-1" {
  subnet_id      = "${aws_subnet.public-1.id}"
  route_table_id = "${aws_route_table.public-rt-1.id}"
}

resource "aws_subnet" "public-2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.public_subnets[1]}"
  availability_zone       = "${var.azs[1]}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_route_table" "public-rt-2" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "Route table - Public subnet 2"
  }
}

resource "aws_route" "public_route-2" {
  route_table_id         = "${aws_route_table.public-rt-2.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "public-rt-asoc-2" {
  subnet_id      = "${aws_subnet.public-2.id}"
  route_table_id = "${aws_route_table.public-rt-2.id}"
}

resource "aws_network_acl" "public-network-acl" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = [ "${aws_subnet.public-1.id}", "${aws_subnet.public-2.id}" ]

  ingress = {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  ingress = {
    protocol = "tcp"
    rule_no = 101
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  ingress = {
    protocol = "tcp"
    rule_no = 102
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  ingress = {
    protocol = "tcp"
    rule_no = 103
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  egress = {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block =  "${aws_vpc.vpc.cidr_block}"
    from_port = 0
    to_port = 0
  }

  egress = {
    protocol = "tcp"
    rule_no = 101
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  egress = {
    protocol = "tcp"
    rule_no = 102
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  egress = {
    protocol = "tcp"
    rule_no = 103
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }
}

##############################
# Private Subnet Configuration
##############################
resource "aws_subnet" "private-1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.private_subnets[0]}"
  availability_zone       = "${var.azs[0]}"

  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_route_table" "private-rt-1" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "Route table - Private subnet 1"
  }
}

resource "aws_route" "private_route-1" {
  route_table_id         = "${aws_route_table.private-rt-1.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id             = "${aws_nat_gateway.nat-1.id}"
}

resource "aws_route_table_association" "private-rt-asoc-1" {
  subnet_id      = "${aws_subnet.private-1.id}"
  route_table_id = "${aws_route_table.private-rt-1.id}"
}

resource "aws_subnet" "private-2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.private_subnets[1]}"
  availability_zone       = "${var.azs[1]}"

  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_route_table" "private-rt-2" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "Route table - Private subnet 2"
  }
}

resource "aws_route" "private_route-2" {
  route_table_id         = "${aws_route_table.private-rt-2.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id             = "${aws_nat_gateway.nat-2.id}"
}

resource "aws_route_table_association" "private-rt-asoc-2" {
  subnet_id      = "${aws_subnet.private-2.id}"
  route_table_id = "${aws_route_table.private-rt-2.id}"
}

resource "aws_network_acl" "private-network-acl" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = [ "${aws_subnet.private-1.id}", "${aws_subnet.private-2.id}" ]
  ingress = {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
  egress = {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
}

#############
# NAT Gateway
#############

resource "aws_eip" "eip-1" {
  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "eip-2" {
  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat-1" {
  allocation_id = "${aws_eip.eip-1.id}"
  subnet_id     = "${aws_subnet.public-1.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat-2" {
  allocation_id = "${aws_eip.eip-2.id}"
  subnet_id     = "${aws_subnet.public-2.id}"

  lifecycle {
    create_before_destroy = true
  }
}
