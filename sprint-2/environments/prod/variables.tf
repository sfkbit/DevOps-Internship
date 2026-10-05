variable "environment" {
  description = "Environment name."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public networks."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private networks."
  type        = list(string)
}

variable "public_gateways" {
  description = "Gateway addresses for public networks."
  type        = list(string)
}

variable "private_gateways" {
  description = "Gateway addresses for private networks."
  type        = list(string)
}
variable "resource_size" {
  description = "Environment resource size profile."
  type        = string
}
