environment   = "prod"
resource_size = "large"

public_subnet_cidrs = [
  "10.30.1.0/24",
  "10.30.2.0/24"
]

private_subnet_cidrs = [
  "10.30.3.0/24",
  "10.30.4.0/24"
]

public_gateways = [
  "10.30.1.1",
  "10.30.2.1"
]

private_gateways = [
  "10.30.3.1",
  "10.30.4.1"
]
