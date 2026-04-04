# create dev namespace

resource "kubernetes_namespace_v1" "dev" {
  depends_on = [module.eks]
  metadata {
    annotations = {
      name = "dev"
    }

    labels = {
      purpose  = "dev_workloads",
      reloader = "enabled"
    }

    name = "dev"
  }
}