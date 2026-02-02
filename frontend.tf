resource "docker_image" "frontend" {
  name = "frontend:latest"
  build {
    context = "${path.module}/frontend"
  }
  force_remove = true
}

resource "docker_container" "frontend" {
  name  = "frontend"
  image = docker_image.frontend.image_id
  ports {
    internal = 80
  }
  networks_advanced {
    name = docker_network.internal_net.name
  }
  restart               = "unless-stopped"
  destroy_grace_seconds = 10
  depends_on            = [docker_container.backend, docker_image.frontend]
}