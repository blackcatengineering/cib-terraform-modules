output "ingress_class" {
  value = "traefik"
}

output "load_balancer_ip" {
  description = "Point DNS (or /etc/hosts) for your ingress hostnames here. Empty until Octavia assigns it."
  value       = try(data.kubernetes_service_v1.traefik.status[0].load_balancer[0].ingress[0].ip, "")
}
