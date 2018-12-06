resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller-cluster-role" {
  metadata {
    name = "tiller-cluster-role"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }
}

provider "helm" {
  host            = "${aws_eks_cluster.eks.endpoint}"
  service_account = "tiller"
  install_tiller  = true

  namespace  = "kube-system"

  kubernetes {
    host                   = "${aws_eks_cluster.eks.endpoint}"
    cluster_ca_certificate = "${base64decode(aws_eks_cluster.eks.certificate_authority.0.data)}"
    token                  = "${data.external.aws_iam_authenticator.result.token}"
  }
}

resource "helm_release" "my_database" {
  name      = "my_datasase"
  chart     = "stable/mariadb"

  set {
    name  = "mariadbUser"
    value = "foo"
  }

  set {
    name = "mariadbPassword"
    value = "qux"
  }
}