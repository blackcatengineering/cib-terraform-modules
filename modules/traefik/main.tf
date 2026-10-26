# Traefik ingress controller. Its Service is type LoadBalancer, which on
# Magnum becomes an Octavia load balancer. HTTP is permanently redirected to HTTPS.
# Routes are plain Kubernetes Ingress objects (ingressClassName: traefik), so
# apps don't depend on Traefik CRDs.

resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode({
    ingressClass = {
      enabled        = true
      isDefaultClass = var.default_ingress_class
    }
    ports = {
      web = {
        http = {
          redirections = {
            entryPoint = { to = "websecure", scheme = "https", permanent = true }
          }
        }
      }
    }
    service = {
      annotations = var.service_annotations
    }
  })]
}

data "kubernetes_service_v1" "traefik" {
  metadata {
    name      = "traefik"
    namespace = var.namespace
  }
  depends_on = [helm_release.traefik]
}
