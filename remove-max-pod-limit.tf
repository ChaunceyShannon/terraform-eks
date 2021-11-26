resource "null_resource" "aws-cni-19" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.9/config/v1.9/aws-k8s-cni.yaml"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = var.kubeconfig_file_path
    }
  }
  depends_on = [
    local_file.kubeconfig_file_path,
  ]
}