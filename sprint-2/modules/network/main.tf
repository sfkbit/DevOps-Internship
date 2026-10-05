terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
resource "docker_network" "public_1" {
  name   = "${var.environment}-public-1"
  driver = "bridge"

  ipam_config {
    subnet  = var.public_subnet_cidrs[0]
    gateway = var.public_gateways[0]
  }
}

resource "docker_network" "public_2" {
  name   = "${var.environment}-public-2"
  driver = "bridge"

  ipam_config {
    subnet  = var.public_subnet_cidrs[1]
    gateway = var.public_gateways[1]
  }
}

resource "docker_network" "private_1" {
  name     = "${var.environment}-private-1"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet  = var.private_subnet_cidrs[0]
    gateway = var.private_gateways[0]
  }
}

resource "docker_network" "private_2" {
  name     = "${var.environment}-private-2"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet  = var.private_subnet_cidrs[1]
    gateway = var.private_gateways[1]
  }
}
