data "aws_ssm_parameter" "cluster" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.demo.version}/amazon-linux-2/recommended/image_id"
}

data "aws_launch_template" "cluster" {
  name = aws_launch_template.cluster.name

  depends_on = [aws_launch_template.cluster] # resource 
}

resource "aws_key_pair" "eks-node" {
  key_name   = "eks-node-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGZEDfct13M+Ou2YUbQL71YoiqmTPwTJjw0hrum/atIccoqGGRkQpRbeJzBgWc+8AqJRDiHt5JjF7N/dTTMH2v7Lyhzj0kfAn5qbSHUaQchiSVuID6azUTFsY6xdZt2XyJrWt+Arkzc417m+nIJqKt61y5ooR3X6bw3BZUHTFPIKtGKhF+F1n88fDIrjI4DRVjEm39NusaJbuT+X5Bm2XVyindmr3UNehPle1A+TrSHaWrtutkbyEaAhEvhCuDJ21HGzJprBz6633MmA7Unw5JiQwoOUVXau0aiHHuzzKYpPaosrBtDFyFwQLjVVm9HBLmHfD86D+/6OUE5A0+kf1Z email@example.com"
}

resource "aws_launch_template" "cluster" {
  image_id               = data.aws_ssm_parameter.cluster.value
  name                   = "eks-launch-template-test"
  update_default_version = true

  key_name = "eks-node-key"
  network_interfaces {
    security_groups = [aws_security_group.demo-cluster.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = tomap({
        "kubernetes.io/cluster/${var.cluster-name}" = "owned",
    })
  }

  user_data = base64encode(templatefile("userdata.tpl", { 
    CLUSTER_NAME = aws_eks_cluster.demo.name, 
    B64_CLUSTER_CA = aws_eks_cluster.demo.certificate_authority[0].data, 
    API_SERVER_URL = aws_eks_cluster.demo.endpoint,
    AMI_ID = data.aws_ssm_parameter.cluster.value,
  }))
}