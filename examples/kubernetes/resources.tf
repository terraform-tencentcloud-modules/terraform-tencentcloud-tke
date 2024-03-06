resource "kubernetes_namespace" "test" {
  depends_on = [tencentcloud_security_group_lite_rule.this]
  metadata {
    name = "nginx"
  }
}

# Define the kubernetes resource, then deploy two pods into the kubernetes cluster
resource "kubernetes_deployment" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "MyTestApp"
      }
    }
    # Set nginx container and corresponding mirror
    template {
      metadata {
        labels = {
          app = "MyTestApp"
        }
      }
      # use Nginx mirror
      spec {
        container {
          image = "nginx"
          name  = "nginx-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Create a kubernetes service which named nginx
resource "kubernetes_service" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  # Mapping NodePort type services to nginx Pods
  spec {
    selector = {
      app = kubernetes_deployment.test.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }
  }
}

# Define a k8s Ingress resource to route external traffic to the Nginx service in the Ingress that named "test-ingress"
resource "kubernetes_ingress_v1" "test" {
  metadata {
    name      = "test-ingress"
    namespace = "nginx"
    annotations = {
      "ingress.cloud.tencent.com/direct-access"     = "false"
      "kubernetes.io/ingress.class"                 = "qcloud"
      "kubernetes.io/ingress.existLbId"             = tencentcloud_clb_instance.ingress-lb.id
      "kubernetes.io/ingress.extensiveParameters"   = "{\"AddressIPVersion\": \"IPV4\"}"
      "kubernetes.io/ingress.http-rules"            = "[{\"path\":\"/\",\"backend\":{\"serviceName\":\"nginx\",\"servicePort\":\"80\"}}]"
      "kubernetes.io/ingress.https-rules"           = "null"
      "kubernetes.io/ingress.qcloud-loadbalance-id" = tencentcloud_clb_instance.ingress-lb.id
      "kubernetes.io/ingress.rule-mix"              = "false"
    }
  }
  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service.test.metadata.0.name
              port {
                number = 80
              }
            }
          }
          path = "/"
        }
      }
    }
  }
}

# deine PVC and PV
resource "kubernetes_persistent_volume_claim" "test" {
  metadata {
    name = "example-pv-claim"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    storage_class_name = "my-storage"
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    volume_name = "${kubernetes_persistent_volume.test.metadata.0.name}"
  }
}

resource "kubernetes_persistent_volume" "test" {
  metadata {
    name = "example-pv"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    storage_class_name = "my-storage"
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      # set the cbs
      csi {
        driver = "com.tencent.cloud.csi.cbs"
        volume_handle = tencentcloud_cbs_storage.stroage.id
        fs_type = "ext4"
      }
    }
  }
}

# define CBS resource
resource "tencentcloud_cbs_storage" "stroage" {
  storage_name      = "example-cbs"
  storage_type      = "CLOUD_SSD"
  storage_size      = 100
  availability_zone = var.available_zone
  project_id        = 0
  encrypt           = false

}