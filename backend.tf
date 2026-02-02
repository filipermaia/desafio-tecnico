resource "docker_image" "backend" {
  name = "backend:latest"
  build {
    context = "${path.module}/backend"
  }
  force_remove = true
}

resource "docker_container" "backend" {
  name  = "backend"
  image = docker_image.backend.image_id
  env = [
    "user=${var.db_user}",
    "pass=${var.db_pass}",
    "db_name=${var.db_name}",
    "host=${var.db_host}",
    "db_port=${var.db_port}",
    "port=${var.back_port}",
    "ADMIN_PASSWORD=${var.admin_password}",
  ]
  ports {
    internal = 3000
  }
  networks_advanced {
    name = docker_network.internal_net.name
  }
  restart               = "unless-stopped"
  destroy_grace_seconds = 10
  depends_on            = [docker_container.postgres, docker_image.backend]
}
