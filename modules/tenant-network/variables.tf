variable "name_prefix" {
  description = "Prefix for resource names, usually the tenant domain (dots become underscores)."
  type        = string
}

variable "external_network" {
  type    = string
  default = "external-network"
}

variable "subnets" {
  description = "Subnet purpose => CIDR"
  type        = map(string)
  default = {
    builder     = "10.0.99.0/24"
    application = "10.0.100.0/24"
  }
}

variable "dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

variable "create_keypair" {
  type    = bool
  default = true
}

variable "public_key" {
  description = "Existing public key to register. Leave null to have Nova generate one (private key then ends up in state)."
  type        = string
  default     = null
}
