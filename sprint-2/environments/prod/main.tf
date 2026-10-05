terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

module "network" {
  source = "../../modules/network"

  environment          = var.environment
  resource_size        = var.resource_size
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  public_gateways      = var.public_gateways
  private_gateways     = var.private_gateways
}
