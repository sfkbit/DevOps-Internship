terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "drift_test" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "drift_test" {
  name  = "sprint-9-drift-test"
  image = docker_image.drift_test.image_id

  labels {
    label = "project"
    value = "sprint-9"
  }

  labels {
    label = "environment"
    value = "test"
  }
}
