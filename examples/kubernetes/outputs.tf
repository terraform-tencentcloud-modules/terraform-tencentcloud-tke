output "load_balancer_ip" {
  description = "Public ip address exposed by load balancer after application deploy finished."
  value       = kubernetes_ingress_v1.test.status.0.load_balancer.0.ingress.0.ip
}