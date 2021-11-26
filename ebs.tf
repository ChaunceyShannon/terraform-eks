
data "aws_eks_cluster_auth" "cluster" {
  name = "my-eks-cluster"
}

data "tls_certificate" "cert" {
  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "openid_connect" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cert.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

provider "kubernetes" {
  host                   = aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority.0.data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.demo.name]
    command     = "aws"
  }
}

module "ebs_csi_driver_controller" {
  source = "DrFaust92/ebs-csi-driver/kubernetes"
  version = "2.10.0"

  oidc_url                                   = aws_iam_openid_connect_provider.openid_connect.url

  depends_on = [
    aws_eks_node_group.demo
  ]
}
