resource "aws_iam_role" "eks_cluster" {
  name = "tech2-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "tech2-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "tech2" {
  name     = "tech2-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.34"

  lifecycle {
  ignore_changes = [tags]
}

  vpc_config {
    subnet_ids = [
      aws_subnet.tech2-public.id,
      aws_subnet.tech2-private.id,
      aws_subnet.tech2-private-2.id
    ]

    security_group_ids = [
      aws_security_group.eks_cluster.id
    ]

    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster
  ]

  tags = {
    Name = "tech2-eks-cluster"
  }
}