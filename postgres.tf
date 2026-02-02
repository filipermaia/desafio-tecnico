resource "docker_volume" "postgres_data" {
  name = "postgres_data"
}

resource "docker_container" "postgres" {
  name  = "postgres"
  image = "postgres:15.8-alpine"
  env = [
    "POSTGRES_PASSWORD=${var.db_pass}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_DB=${var.db_name}",
  ]
  volumes {
    host_path      = abspath("${path.module}/sql/script.sql")
    container_path = "/docker-entrypoint-initdb.d/init.sql"
    read_only      = true
  }
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  ports {
    internal = 5432
  }
  networks_advanced {
    name = docker_network.internal_net.name
  }
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
  restart               = "unless-stopped"
  destroy_grace_seconds = 10
  wait                  = true
  depends_on            = [docker_network.internal_net, docker_volume.postgres_data]
}
