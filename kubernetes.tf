data "external" "aws_iam_authenticator" {
  program = ["bash", "${path.module}/scripts/dependencies.sh"]

  query {
    cluster_name = "${var.cluster_name}"
  }
}

provider "kubernetes" {
  host                   = "${aws_eks_cluster.eks.endpoint}"
  cluster_ca_certificate = "${base64decode(aws_eks_cluster.eks.certificate_authority.0.data)}"
  token                  = "${data.external.aws_iam_authenticator.result.token}"
  load_config_file       = false
}


resource "kubernetes_storage_class" "gp2" {
  metadata {
    name = "standard"
  }

  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters {
    type      = "gp2"
    fsType    = "ext4"
    encrypted = false
  }
}

resource "kubernetes_service_account" "eks-admin" {
  metadata {
    name      = "eks-admin"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "eks-admin-crb" {
  metadata {
    name = "eks-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = "eks-admin"
    namespace = "kube-system"
  }
}

resource "kubernetes_config_map" "aws-auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data {
    mapRoles = <<ROLES
  - rolearn: ${aws_iam_role.eks-node.arn}
    username: system:node:{{EC2PrivateDNSName}}
    groups:
      - system:bootstrappers
      - system:nodes
    ROLES
  }
}
