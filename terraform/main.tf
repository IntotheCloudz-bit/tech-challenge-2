resource "aws_vpc" "tech2-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tech2-vpc"
  }
}

resource "aws_subnet" "tech2-public" {
  vpc_id                  = aws_vpc.tech2-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tech2-public-subnet"
  }
}

resource "aws_subnet" "tech2-private" {
  vpc_id            = aws_vpc.tech2-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tech2-private-subnet"
  }
}

resource "aws_subnet" "tech2-private-2" {
  vpc_id            = aws_vpc.tech2-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "tech2-private-subnet-2"
  }
}

resource "aws_internet_gateway" "Tech2-IGW" {
  vpc_id = aws_vpc.tech2-vpc.id

  tags = {
    Name = "tech2-igw"
  }
}


resource "aws_route_table" "tech2-public" {
  vpc_id = aws_vpc.tech2-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Tech2-IGW.id
  }

  tags = {
    Name = "tech2-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.tech2-public.id
  route_table_id = aws_route_table.tech2-public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "tech2-nat-eip"
  }
}

resource "aws_nat_gateway" "tech2-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.tech2-public.id

  tags = {
    Name = "tech2-nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.Tech2-IGW
  ]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.tech2-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tech2-nat.id
  }

  tags = {
    Name = "tech2-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.tech2-private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "eks_cluster" {
  name        = "tech2-eks-cluster-sg"
  description = "Security group for Tech Challenge 2 EKS cluster"
  vpc_id      = aws_vpc.tech2-vpc.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tech2-eks-cluster-sg"
  }
}

