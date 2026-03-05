resource "docker_network" "external_net" {
  name   = "external_net"
  driver = "bridge"
}

resource "docker_network" "internal_net" {
  name     = "internal_net"
  driver   = "bridge"
  internal = true
}