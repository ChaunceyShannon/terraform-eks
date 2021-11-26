
resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "demo"
  node_role_arn   = aws_iam_role.demo-node.arn
  subnet_ids      = aws_subnet.demo-private[*].id
  instance_types  = ["t2.medium"] 

  # Run node with launch_template
  # launch_template {
  #   id      = data.aws_launch_template.cluster.id
  #   version = data.aws_launch_template.cluster.latest_version
  # }

  # Run node without launch_template
  remote_access {
    ec2_ssh_key = "eks-node-key"
    # If not specify source_security_group_ids will open 22 port to the world 
    # source_security_group_ids = [aws_security_group.demo-cluster.id] 
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
