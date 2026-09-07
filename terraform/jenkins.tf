resource "aws_instance" "jenkins" {
  ami                         = "ami-025d99823a4caad37"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.tech2-public.id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  key_name                    = "KEY-Pair_Cloudz"
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true

  tags = {
    Name = "tech2-jenkins"
  }
}


resource "aws_security_group" "jenkins" {
  name        = "tech2-jenkins-sg"
  description = "Security group for Tech Challenge 2 Jenkins server"
  vpc_id      = aws_vpc.tech2-vpc.id

  tags = {
    Name = "tech2-jenkins-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh" {
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_web" {
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "jenkins_all" {
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_iam_role" "jenkins" {
  name = "tech2-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "tech2-jenkins-role"
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "tech2-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

resource "aws_iam_role_policy" "jenkins_eks" {
  name = "tech2-jenkins-eks"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = "arn:aws:eks:us-east-1:701559402152:cluster/tech2-eks-cluster"
      }
    ]
  })
}

resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = aws_eks_cluster.tech2.name
  principal_arn = aws_iam_role.jenkins.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = aws_eks_cluster.tech2.name
  principal_arn = aws_iam_role.jenkins.arn
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
