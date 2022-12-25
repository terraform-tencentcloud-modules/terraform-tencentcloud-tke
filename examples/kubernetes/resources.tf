resource "kubernetes_namespace" "test" {
  depends_on = [tencentcloud_security_group_lite_rule.this]
  metadata {
    name = "nginx"
  }
}

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
    template {
      metadata {
        labels = {
          app = "MyTestApp"
        }
      }
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

resource "kubernetes_service" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
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
    #    selfLink = "/apis/networking.k8s.io/v1/namespaces/nginx/ingresses/test-ingress"
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
