variable "cluster-name" {
  default = "terraform-eks-demo"
  type    = string
}

variable "aws_region" {
  default = "ap-south-1"
}

variable "aws_profile" {
  default = "kk"
}

variable "eks_version" {
  default = "1.21"
}

variable "kubeconfig_file_path" {
  default = "/root/.kube/config"
}
