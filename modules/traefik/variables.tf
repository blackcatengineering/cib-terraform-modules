variable "chart_version" {
  type    = string
  default = "42.1.3"
}

variable "namespace" {
  type    = string
  default = "traefik"
}

variable "default_ingress_class" {
  type    = bool
  default = true
}

variable "service_annotations" {
  description = "Extra annotations on the LoadBalancer Service (e.g. Octavia/CCM options)."
  type        = map(string)
  default     = {}
}
