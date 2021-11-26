# Create EFS storage 
resource "aws_efs_file_system" "eks-efs" {
    tags = {
      "efs.csi.aws.com/cluster" = "true",
    }
}
# Set the EFS service access endpoint to the private subnet, so that the EKS node can mount EFS filesystem 
resource "aws_efs_mount_target" "eks-efs" {
  count = 2

  file_system_id = aws_efs_file_system.eks-efs.id
  subnet_id      = aws_subnet.demo-private.*.id[count.index]
}

# iam
resource "aws_iam_role" "demo-efs" {
  name = "terraform-eks-demo-efs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "efs_controller_policy_doc" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "ec2:DescribeAvailabilityZones",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values = [
        "true"
      ]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values = [
        "true"
      ]
    }
  }
}

resource "aws_iam_policy" "efs_controller_policy" {
  name_prefix = "efs-csi-driver-policy"
  policy      = data.aws_iam_policy_document.efs_controller_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "efs-policy-attachment" {
  policy_arn = aws_iam_policy.efs_controller_policy.arn
  # role       = aws_iam_role.demo-efs.name
  role = aws_iam_role.demo-node.name
}

# helm
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.demo.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority.0.data)

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.demo.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "aws-efs-csi-driver" {
  name       = "aws-efs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"
}

# kubernetes
resource "kubernetes_storage_class" "eks-efs" {
  metadata {
    name = "eks-efs"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  parameters = {
    "provisioningMode" = "efs-ap"
    "fileSystemId"     = aws_efs_file_system.eks-efs.id
    "directoryPerms"   = "700"
    "basePath"         = "/data/efs" # optional
  }
}