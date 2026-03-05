module "app" {
  source = "./modules/application"

  db_host        = var.db_host
  db_name        = var.db_name
  db_port        = var.db_port
  db_user        = var.db_user
  db_pass        = var.db_pass
  admin_password = var.admin_password
  back_port      = var.back_port
}