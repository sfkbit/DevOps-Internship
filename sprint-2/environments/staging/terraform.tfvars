environment   = "staging"
resource_size = "medium"

public_subnet_cidrs = [
  "10.20.1.0/24",
  "10.20.2.0/24"
]

private_subnet_cidrs = [
  "10.20.3.0/24",
  "10.20.4.0/24"
]

public_gateways = [
  "10.20.1.1",
  "10.20.2.1"
]

private_gateways = [
  "10.20.3.1",
  "10.20.4.1"
]
