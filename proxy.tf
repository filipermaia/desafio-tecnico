resource "docker_container" "proxy" {
  name  = "proxy"
  image = "nginx:alpine"
  ports {
    internal = 80
    external = 8080
  }
  volumes {
    host_path      = abspath("${path.module}/proxy/nginx.conf")
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }
  networks_advanced {
    name = docker_network.external_net.name
  }
  networks_advanced {
    name = docker_network.internal_net.name
  }
  restart               = "unless-stopped"
  destroy_grace_seconds = 10
  depends_on            = [docker_network.external_net, docker_container.frontend]
}
