## storage classes

resource "kubernetes_storage_class_v1" "gp3" {
  depends_on = [module.eks]

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = "true"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Retain"
  parameters = {
    fsType    = "ext4"
    type      = "gp3"
    encrypted = true
  }
  mount_options = []
}

resource "kubernetes_storage_class_v1" "efs" {
  depends_on = [module.eks]

  metadata {
    name = "efs"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = var.efs_file_system_id
    directoryPerms   = "700"
  }

  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}
