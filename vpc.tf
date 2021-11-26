#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

# Create a VPC 
# Create 6 subnets inside 3 availability zones, create a public subnet and a private subnet for each availability zone 
# Create an internet gateway 
# Set a route table to each public subnet to transfer data to the internet, through the internet gateway  

# Create a VPC 
resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

# Setup default security grou for the vpc
#   Allow connections only from private network 10.0.0.0/16
#   Allow all connections to the internet 
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.demo.id

  ingress  = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      self = true
      cidr_blocks = ["10.0.0.0/16"]
      description = "self"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
    }
  ]

  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "self"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      self = true
      security_groups = []
    }
  ]
}

# Create private subnets across 3 availability zone, instance inside these subnet will not get a public IP address 
resource "aws_subnet" "demo-private" {
  count = 3
  
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"][count.index]
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.demo.id

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
    "kubernetes.io/role/internal-elb"           = 1
  })
}

# Create public subnets across 3 availability zone, instance inside these subnet will get a public IP address
# Later we will put a Jump Server instance here so that we can ssh to the eks nodes throught the Jump Server  
resource "aws_subnet" "demo-public" {
  count = 3
  
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = ["10.0.252.0/24", "10.0.253.0/24", "10.0.254.0/24"][count.index]
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.demo.id

  tags = tomap({
    "Name"                   = "terraform-eks-demo-node",
    "kubernetes.io/role/elb" =  1,
  })
}

# Add an internet gateway to the VPC
resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "terraform-eks-demo"
  }
}

# Add a route table that send all data to internet through the internet gateway 
resource "aws_route_table" "demo-internet-gateway" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }
}

# Attach the route table to all the public subnets 
resource "aws_route_table_association" "demo-public" {
  count = 3
  
  subnet_id      = aws_subnet.demo-public.*.id[count.index]
  route_table_id = aws_route_table.demo-internet-gateway.id
}

# Add 3 elastic ips, it will be attach to nat gateway and will be used by EKS nodes to transfer data to the internet 
resource "aws_eip" "nat-gateway" {
  count = 3
}

# Create nat gateways inside each public subnet 
resource "aws_nat_gateway" "demo" {
  count = 3

  subnet_id     = aws_subnet.demo-public.*.id[count.index]
  depends_on = [aws_internet_gateway.demo]
  allocation_id = aws_eip.nat-gateway.*.id[count.index]
}

# Add another route table, this is for private subnet 
# The destination is internet gateway but nat gateway.
resource "aws_route_table" "demo-nat-gateway" {
  count = 3

  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.demo.*.id[count.index]
  }
}

# Add the route table to private network.
resource "aws_route_table_association" "demo-private" {
  count = 3

  subnet_id      = aws_subnet.demo-private.*.id[count.index]
  route_table_id = aws_route_table.demo-nat-gateway.*.id[count.index]
}
