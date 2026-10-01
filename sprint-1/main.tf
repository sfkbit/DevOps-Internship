terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "public_1" {
  name   = "sprint-1-public-1"
  driver = "bridge"

  ipam_config {
    subnet  = var.public_subnet_cidrs[0]
    gateway = "10.0.1.1"
  }
}

resource "docker_network" "public_2" {
  name   = "sprint-1-public-2"
  driver = "bridge"

  ipam_config {
    subnet  = var.public_subnet_cidrs[1]
    gateway = "10.0.2.1"
  }
}

resource "docker_network" "private_1" {
  name     = "sprint-1-private-1"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet  = var.private_subnet_cidrs[0]
    gateway = "10.0.3.1"
  }
}

resource "docker_network" "private_2" {
  name     = "sprint-1-private-2"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet  = var.private_subnet_cidrs[1]
    gateway = "10.0.4.1"
  }
}
